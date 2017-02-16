class Property < ActiveRecord::Base

  has_many :photos, foreign_key: :propid
  has_one :apn, foreign_key: :propid
  
  self.inheritance_column = nil # required because property table has a type
  # column, and that is a reserved name used for Single Table Inheritance
  # per convention.  If need STI, change nil to :sti_type and probably
  # add a migration to add that column to the DB.  DDC

  self.table_name = "property"

  ###########################################################################
  # #Property#find_by_loose_address
  
  # Find a property by a street address that is quite possibly not in the
  # same syntactical (lexical?) form used by the database.
  #
  # Meaning, the database uses "123 Great St", "456 Rails Rules Ave", etc.,
  # but the addresses typed by a usertypes might include "Street" or "St." or
  # "Avenue" or "Ave." or, for that matter, "Mount" instead of "Mt", "East" 
  # instead of "E", etc.  This routine will do most of the common conversions
  # so the property is found even if the way it is typed is any of the common
  # forms that the database does not use.
  #
  # Note: Below worked for mysql2 which does case-insensitive matching:
  #    @property = Property.find_by address1: addr_normalized
  # but sqlite only does case-insensitive matching in LIKE statements,
  # not in regular "=" expressions. Got this from: 
  # http://stackoverflow.com/questions/2220423/
  #   case-insensitive-search-in-rails-model
  # The reply that starts with: "Quoting from the SQLite documentation:")
  #
  # @param addr [String] a street address without city, state, or zip; does
  #   not need to be in any specific form (e.g. St, St., Street all work)
  # 
  # @return [Property] if the address is found in the database
  #
  # @return [nil] if the address does not exist in the database, or if
  #   the canonicalization routine (normalize_address) can't convert
  #   the spelling of the address into the standard format.
  def self.find_by_loose_address(addr)
    addr_normalized = ApplicationController.helpers.normalize_address(addr)
      
    logger.debug "Hand-typed address (not selected from dropdown list): (" +
      addr + ")"
    logger.debug "  Address text normalized to: (#{addr_normalized})"

    # Use LIKE to work with sqlite as well as mysql2, 
    # instead of find_by(:name,...) 
    Property.where("address1 LIKE ?", "%#{addr_normalized}%")[0]
  end

  #
  # Instance methods below
  #
  
  
  ###########################################################################
  # #Property.get_photo_filename
  
  # Return filename of first photos, or return filename of placeholder 
  # cartoon image if nil.
  #
  # @return [String] a valid image filename, either of the property, or
  #   of a cartoon placeholder image.
  def get_photo_filename()
    s = self.photos.first;
    if s == nil
      "house-stick-figure-med.png" # perhaps make this non-hard-coded somehow
    else
      s.filename
    end
  end
  
end
