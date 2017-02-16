require 'fuzzystringmatch'
#############################################################################
# PropertiesHelper
#
# Since 1/20/17 Derek Carlson <carlson.derek@gmail.com>
#############################################################################
module PropertiesHelper
  include UtilGlobals

  ###########################################################################
  # #normalize_address

  # Convert common ways to type addresses (St or St. or Street, etc.) into
  # the consistent way used in the database (address1 field).
  #
  # @param addr [String] the raw address
  #
  # @return [String] the address converted into a format used in the database
  #
  # Handles multiple whitespace before, after, and between words, 
  # including tabs.
  #
  # Example: '1099 Mt   Lowe Drive' => '1099 MT LOWE DR'  
  # Example: '419 West Palm St.' => '419 W PALM ST'
  #
  # Misc notes:
  #
  #   * Mt Curve and Mt Lowe (turn Mount to Mt) 
  #   * E, N, W, S Altadena Drive (and a lot others): Turn EAST -> E, etc.  
  #   * Way (all *Way's end in Way, except 796 Fontanet Wy)
  #   * Inconsistent data in the database as of 1/11/17 DDC: South and Palmyra 
  #     (both are names of the street and lack a trailing designation such as
  #     St or Rd, etc.)
  #
  ###########################################################################
  def normalize_address(addr)
    #### paranoia checks ####
    if ( !(addr).is_a?(String) || addr.length == 0 ) 
      log_paranoia_check("Bad parameter: addr (" + addr.to_s + "). Should " +
        "be a String and non-zero length.")
      return addr # not sure, maybe should be ""
    end
    #### end paranoia checks ####
    
    addr.upcase!
    # remove leading and trailing whitespace
    addr = addr.match(/\s*([^\s].*[\S])\s*/).captures[0]
    # remove multiple whitespace chars between words
    addr.gsub!(/(\S)\s\s+(\S)/,'\1 \2')
    # turn lone tabs into spaces
    addr.gsub!(/\t/, ' ')
    # remove . at end of ST., AVE., etc.
    addr.gsub!(/\.$/, '')

    street_name_xfms = {
      'ST': "STREET$",
      'AVE': "AVENUE$",
      'BLVD': "BOULEVARD$",
      'RD': "ROAD$",
      'DR': "DRIVE$",
      'PL': "PLACE$",
      'LN': "LANE$",
      'CIR': "CIRCLE$",
      'TER': "TERRACE$",
      'CT': "COURT$",      
      'TR': "TRAIL$",      
      'WAY': "WY$",  # yes, this one is opposite the others      
      ' N ': " NORTH ", ' S ': " SOUTH ", ' E ': " EAST ", ' W ': " WEST ",
      ' MT ': " MOUNT "
    }

    street_name_xfms.each do |k, v|
      addr.gsub!(/#{v}/, k.to_s) 
    end

    addr
  end

  # TODO: Fill in comments
  def get_photo_div_html(html, ph)
    (ph[:photofname] =~ /photo/) ? 
      pre = "http://altadenaheritagepdb.org/photo/" : pre = ""
    html += 
      ("<div id='pnf_suggested_container'>" + 
          image_tag(pre + ph[:photofname], :id => 'pnf_suggested_photo',
            :alt => 'Photo') + 
          "<div id='pnf_suggested_addr'> " +
            "<a href=\"#{property_path(ph[:id])}\">#{ph[:address]}</a> " +
          "</div>" +
         "</div>").html_safe
  end

  ###########################################################################
  # #get_neighbors

  # Format the output neighbors routine into a comma separated HTML
  # list of neighboring properties, where each property
  # in the list is hyperlinked to its property page.
  #
  # @param addr [String] the address to find neighbors of
  #
  # @return [Hash] { :num [Integer] - the number of matches,
  #   :html [String] - comma separated list of neighboring properties
  #   hyperlinked to their property#show pages.
  #
  # @return [Nil] if no neighbors are found
  def get_neighbors(addr)
    ar_h_matches = neighbors(addr)
    html = ""
    num = 0
    if ar_h_matches.length > 0
      ar_h_matches.each do | ph |
        html = get_photo_div_html(html, ph)
        num += 1
      end
      return { num: num, html: html.gsub(/(.*), $/, '\1').html_safe }
    else
      return nil
    end
  end
  
  ###########################################################################
  # #get_similar_addresses

  # Format the output from the three address matching routines into an HTML
  # list of matching properties (usually just one), where each property
  # in the list is hyperlinked to its property page.
  #
  # @param addr [String] the address to find matches for
  #
  # @return [Hash] { :num [Integer] - the number of matches,
  #   :html [String] - comma separated list of matching properties
  #   hyperlinked to their property#show pages.
  #
  # @return [Nil] if no similar matches are found
  def get_similar_addresses(addr)

    ar_h_matches = same_addr_num_and_first_letter(addr)
    ar_h_matches |= same_addr_another_desigation(addr)
    ar_h_matches |= fuzzy_addr_matcher(addr)
    
    html = ""
    num = 0
    if ar_h_matches.length > 0
      ar_h_matches.each do | ph |
        html = get_photo_div_html(html, ph)
        num += 1
      end
      return { num: num, html: html.gsub(/(.*), $/, '\1').html_safe }
    else
      return nil
    end
  end
  
  ###########################################################################
  # #same_addr_num_and_first_letter
  
  # Find a property with the same number and a street name that starts
  # with the same letter.  For instances when the user brain-farts and
  # types 'Alta Pine' really means 'Alta Vista'.
  #
  # Example: If we provide: 945 Alta Pine Dr (not in the DB, by the way)
  #          Then this returns [{ id: 10302, address: "945 Alta Vista Dr" }]
  #
  # @param addr [String]
  #
  # @return [Array] [], if no valid property is found with the same number and
  #   the same first letter of the street name.
  #
  # @return [Array] of hashes of the form { id: , address: }, that
  #   represent valid properties in the database that match the
  #   street number and the first letter of the street name.
  #
  # @author Derek Carlson <carlson.derek@gmail.com
  def same_addr_num_and_first_letter(addr)
    addr.upcase!

    # If addr doesn't match this pattern, everything else
    # fails below, so [f|b]ail fast and just return []
    if addr !~ /^(\d+) (.*) (.*)$/
      return []
    end

    num_n_letter = addr.gsub(/^(\d+ .).*$/,'\1')
    ar_h_matches = []
    props = Property.where("address1 LIKE '#{num_n_letter}%'")
    # as long as we use LIKE, sqlite will match case-insensitive
    # (mysql always matches case-insensitive)
    props.each do | p |
      ar_h_matches << { id: p.id, address: p.address1, 
        photofname: p.get_photo_filename }
    end
    ar_h_matches 
  end

  
  ###########################################################################
  # #same_addr_another_desigation
  
  # Find a property with the same number and street name but a different
  # designation (St, Ave, etc.)  Used for situations when an address is 
  # not found, and it's because the user typed in the wrong designation.
  #
  # Example: If we provide: 653 Alameda Ave (not in the DB, by the way)
  #          Then this returns [{ id: 10064, address: "653 Alameda St" }]
  #
  # @param addr [String]
  #
  # @return [Array] [], if no property is found with the same number and
  #   street name but a different designation.
  #
  # @return [Array] of hashes of the form { id: , address: }, that
  #   represent valid properties in the database that match the
  #   street number and street name but with a different designation (St, 
  #   Ave, etc.).  In theory this should be a list of, at most, one 
  #   property.
  #
  # @author Derek Carlson <carlson.derek@gmail.com
  def same_addr_another_desigation(addr)
    addr.upcase!

    # If addr doesn't match this pattern, everything else
    # fails below, so [f|b]ail fast and just return []
    if addr !~ /^(\d+) (.*) (.*)$/
      return []
    end

    wo_desig = addr.gsub(/^(\d+ .*) .*$/,'\1')
    ar_h_matches = []
    props = Property.where("address1 LIKE '#{wo_desig}%'")
    # as long as we use LIKE, sqlite will match case-insensitive
    # (mysql always matches case-insensitive)
    props.each do | p |
      ar_h_matches << { id: p.id, address: p.address1, 
        photofname: p.get_photo_filename }
    end
    ar_h_matches 
  end

  ###########################################################################
  # #fuzzy_addr_matcher
  
  # Take a possibly typoed street name, look for another address with
  # the same street number and a similar street name (ignore the 
  # designator, like 'St', entirely), and if a similar street name is
  # found, see if we have a property in the database at the same street
  # number but with the alternative street name.  If a match is found,
  # return the full new address as a possible match.
  # 
  # Example: 653 Alameca St -- that's a typo
  #           [1] Look for similar street names to 'Alemaca'
  #           [2] 'Alaca' and 'Alameda' are found at a 90% match
  #           [3] 653 Alaca St -- no such address, so ignored
  #           [4] 653 Alameda St -- this is an actual address
  #               in our database, so it's suggested as a possible match
  #               and perhaps what the user meant (minus the typo);
  #               thus we return [{ id: 10064, address: "653 Alameda St"}]
  #
  # @param street [String] the full street address (number and
  #   designation will be stripped prior to matching)
  #
  # @param thresh [Float] the matching threshold above which is
  #   considered a close match. 0.90 works pretty well.
  #
  # @return [Array] [], if no matches are found
  #
  # @return [Array] of hashes of the form { id: , address: }, that
  #   represent valid properties in the database that are fuzzy
  #   matches to the input address.
  #
  # @author Derek Carlson <carlson.derek@gmail.com
  def fuzzy_addr_matcher(addr, thresh=0.90)
    addr.upcase!
    
    # If addr doesn't match this pattern, everything else
    # fails below, so [f|b]ail fast and just return []
    if addr !~ /^(\d+) (.*) (.*)$/
      return []
    end

    # Remove number and designation
    num = addr.gsub(/^(\d+) .*$/,'\1')  
    desig = addr.gsub(/^\d+ .* (.*)$/,'\1')  
    street = addr.gsub(/^\d+ (.*) .*$/,'\1') 
    ar_h_valid_similar_addresses = []
    jarow = FuzzyStringMatch::JaroWinkler.create( :native )

    streets = Property.distinct.pluck(:streetname)

    streets.each do | st |
      st.gsub!(/^(.*) .*$/, '\1') # remove designation (St, Ave, etc.)
      if jarow.getDistance(st, street) > 0.90
        
        log_debug "Fuzzy Match: " + st + " to originally typed " + street

        possible_addr = num + " " + st + " " + desig

        log_debug "  Does the DB contain: " + 
          possible_addr + "?"
          
        # Make sure the possible address actually exists in our database
        # before we suggest it as a possibility.
        
        #@prop = Property.find_by(:address1 => possible_addr) 
        # above commented out - although it is far faster,
        # as long as we use LIKE, sqlite will match case-insensitive
        # (mysql always matches case-insensitive)
        props = Property.where("address1 LIKE '%#{possible_addr}%'")
        
        if props.length > 0
          log_debug "  Yes!  Adding " + 
            possible_addr + " as a possible alternative."
          ar_h_valid_similar_addresses <<
            { id: props[0][:id], address: props[0][:address1],
              photofname: props[0].get_photo_filename }
        else
          log_debug "  " + possible_addr + 
            " is not an address in the database, so tossing it as " +
            "a possibility."
        end
      end
    end
    ar_h_valid_similar_addresses
  end  # fuzzy_addr_matcher

  ###########################################################################
  # #neighbors
  
  # Get the neighboring houses on a street within a given range of addresses.
  # Used when an address is not found in the DB, and we want to offer the
  # user the possibility to look around at neighboring properties in case
  # they can glean some useful information from that.
  #
  # @param addr [String]
  #
  # @param before [Integer] [Optional] how far below the address number to 
  #   include.  Defaults to 20.  Thus, if the address is 651, then this
  #   routine will look to return all valid properties from 631 to 671.
  #
  # @param after [Integer] [Optional] same as 'before', but how far above.
  #
  # @return [Array] [], if no matches are found
  #
  # @return [Array] of hashes of the form { id: , address: }, that
  #   represent valid properties in the database that are neighbors
  #   within the requested range.
  #
  # @author Derek Carlson <carlson.derek@gmail.com
  def neighbors(addr, before=20, after=20)
    addr.upcase!
    
    # If addr doesn't match this pattern, everything else
    # fails below, so [f|b]ail fast and just return []
    if addr !~ /^(\d+) (.*) (.*)$/
      return []
    end
    
    num = addr.gsub(/^(\d+) .*$/,'\1').to_i
    street_name_only = addr.gsub!(/^\d+ (.*)$/,'\1') 
    low = (num - before < 0 ? 0 : num - before)
    high = num + after 
    
    log_debug "Looking for neighbors to " +
      addr + " in the range from " + low.to_s + " to " + high.to_s

    ar_h_close_addresses = []
    if false
      query = "streetnumberbegin >= #{low} and " +
        "streetnumberbegin <= #{high} and " +
        "streetname LIKE \"%#{street_name_only}%\""
      # as long as we use LIKE, sqlite will match case-insensitive
      # (mysql always matches case-insensitive)
        
      log_debug "  Running Property.where query: " + query
      
      ar_po_close = Property.where(query)
    else
      # New idea: Find neighbor to the left and right, if exist.
      # The lower address neighbor:
      query = "streetnumberbegin < #{num} and " +
        "streetname LIKE \"%#{street_name_only}%\""
      
      log_debug "  Finding closest neighbor below..."
      ar_po_close = Property.where(query).order(
        'streetnumberbegin desc').limit(1)

      query = "streetnumberbegin > #{num} and " +
        "streetname LIKE \"%#{street_name_only}%\""

      log_debug "  Finding closest neighbor above..."
      ar_po_close += Property.where(query).order(
        'streetnumberbegin asc').limit(1)
    end
    
    ar_po_close.each do | p |
      ar_h_close_addresses << { id: p.id, address: p.address1, 
        photofname: p.get_photo_filename }
    end
    ar_h_close_addresses 
  end # neighbors
  
end # PropertiesHelper