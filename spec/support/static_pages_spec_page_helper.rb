#############################################################################
# module StaticPagesSpecPageHelper
#
# Abstracts away all css-specific capybara commands for spec'ing the
# various pages of the StaticPages controller.
#
# Includes the infamous routines to have capybara work propertly with
# select2 and selenium.  Ooooh, that one was hard to figure out.  
#
# Since 1/19/2017 Derek Carlson <carlson.derek@gmail.com>
#############################################################################
module StaticPagesSpecPageHelper

  # The canonical code, whatever it happens to be, for verifying that
  # the home page is up.
  def be_the_home_page
    have_css("#sp-home-ad-box", 
      :text => "Architectural Database", :wait => 5) 
  end
  
  ###########################################################################
  # #HomePageSpecPageHelper
  
  # Abstracts all css-specific capybara commands for the home page.
  # Returns self on all methods, allowing a slick fluent chaining
  # syntax in the static pages spec.  If the page design or css
  # naming changes, here is the only place you'll need to go to
  # update the spec.
  #
  # @author Derek Carlson <carlson.derek@gmail.com>
  #
  ###########################################################################
  class HomePageSpecPageHelper
    include Capybara::DSL
    include WaitForAjax
    
    # Visit the home page
    #
    # @return self
    def visit_page
      visit "/"
      self
    end
    
    # Click the Search button on the home page
    #
    # @return self
    def click_search
      click_button("sp-home-search-btn")
      self
    end
    
    # Select an item in a select2 element by clicking on an
    # item in the dropdown list.
    #
    # @param name_or_list_index [String, Integer] either the 
    #   name of an item in the dropdown list, or the index
    #   of the item in the dropdown list, where the first
    #   item's index is 1.
    #
    # @return self
    def click_select2_item(name_or_list_index)
      find("#select2-sp-home-addr-select2-container").click
      wait_for_ajax
      
      if name_or_list_index.class == Fixnum
        find(".select2-results li:nth-child(#{name_or_list_index})").click
      else
        # Found this idea at: http://stackoverflow.com/questions/12771436/
        #   how-to-test-a-select2-element-with-capybara-dsl, the last
        #   answer.
        within ".select2-results" do
          find("li", text: name_or_list_index).click
        end
      end
      self
    end
  
    ###########################################################################
    # #type_text_for_existing_item_into_select2
    
    # Type text into a select2 search feild specifically when that typed text 
    # is *exactly the same* as one of the items in the dropdown list.  This is
    # important, because capybara+select2 work differently depending on whether
    # the typed item is in the list or not.
    #
    # @author Derek Carlson <carlson.derek@gmail.com>
    #
    # @param stuff [String] the text to be typed into the select2 search field
    #
    # @return self
    #
    # We have capybara type into a text box marked as .select2-search__field.  
    # In order to get the typed text to "register", we have to add a \n to the
    # text because that simulates the hitting of the enter key -- otherwise 
    # the text never gets copied from the .select2-search__field into the actual
    # value of the select2 element that the page uses when the form submits 
    # (which is the #select2-sp-home-addr-select2-container element, which
    # controls the value for the original #sp-home-addr-select2 select element
    # which is the element with name="id" that is passed to the controller
    # as params[:id]
    def type_text_for_existing_item_into_select2(stuff)
      find("#select2-sp-home-addr-select2-container").click
      wait_for_ajax
      find(".select2-search__field", wait: 5).set(stuff + "\n")
      # For who-knows-what-reason, unlike the similar case for typing
      # in the text of an item that doesn't exist in the dropdown list,
      # the .set() above with the \n is enough to ensure that the value
      # of .select2-search__field gets copied into
      # #select2-sp-home-addr-select2-container before the code continues,
      # preventing race conditions.  Unlike the other case, the second
      # find, commented out below, isn't necessary in this case.
      #
      # find("#select2-sp-home-addr-select2-container", text: stuff)
      self
    end

    ###########################################################################
    # #type_text_for_unlisted_item_into_select2
    
    # Type text into a select2 search field specifically when that typed text 
    # is not any of the items in the dropdown list.  This is important, 
    # because capybara+select2 work differently depending on whether the typed 
    # item is in the list or not.
    #
    # @author Derek Carlson <carlson.derek@gmail.com>
    #
    # @param stuff [String] the text to be typed into the select2 search field
    #
    # @return self
    #
    # Apparently find(".select2-search__field", wait: 5).set(stuff)
    # initiates a copy of the text in .select2-search__field over to
    # #select2-sp-home-addr-select2-container, but this takes some
    # time to complete.  Without the following second find command
    # that waits for the text to appear in 
    # #select2-sp-home-addr-select2-container, the code just blazes
    # on past and #select2-sp-home-addr-select2-container is still
    # nil (for a moment), thus the original select element 
    # (#sp-home-addr-select2) that it controls is also nil, thus
    # the search button gets clicked too fast resulting in the
    # controller getting sent a nil for params[:id] as opposed to the
    # id of the item typed. 
    #
    # BTW, the id of an item NOT in the list is the actual text you typed
    # -- e.g. if you typed "1234 Fred St", the id (params[:id]) also is
    # "1234 Fred St".  This is achieved in static_pages.js where the
    # select2 options are set - see the comments there to learn how
    # this is made available.
    # 
    # Thus, the second find command is necessary to wait for the
    # typed value to transfer, and prevents the race condition and
    # the sending of a nil id.
    def type_text_for_unlisted_item_into_select2(stuff)
      find("#select2-sp-home-addr-select2-container").click
      wait_for_ajax
      find(".select2-search__field", wait: 5).set(stuff)
      find("#select2-sp-home-addr-select2-container", 
        text: stuff)
      self
    end
  
  end # class HomePageSpecPageHelper
end # module StaticPagesSpecPageHelper

RSpec.configure do |config|
  config.include StaticPagesSpecPageHelper, :type => :feature
end
