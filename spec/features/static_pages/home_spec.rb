require 'rails_helper'
require 'pry-byebug'
#############################################################################
# home_spec.rb
#
# JavaScript/Selenium feature tests for the home page.
#
# Tests:
#
# 1. Click a property from the dropdown list and click search.
# 2. Type in a valid property in the text field and click search.
#     => Both 1 & 2 lead to property found page. 
#
# 3. Type in a property we do NOT have in the text field and click search.
#     => Show property not found page.  
#
# 4. Just click search with nothing selected or touched.
#     => For now should do nothing, but perhaps check for some css being
#        visible saying "fill this in" in the future
#
# 5. UNNECESSARY: Type a space or two and click search.
#     Turns out select2 (on Firefox at least) does not allow typing
#     just a few spaces or even a tab.  If you type a few spaces and click
#     Search, the second you click Search select2 loses focus, erases
#     the text input field and dropdown list, and never puts those 2 spaces
#     into the actual select2 control itself.  If you hit tab or a few
#     spaces and a tab, it just erases the text input field in the same
#     manner, and never copies any of that whitespace into the control
#     itself.  Thus, the underlying element that matters - the original
#     select element that was turned into select2 - it never gets a value
#     of just whitespace.
#
# Notes:
#
#   In the body of a spec, can insert "binding.pry" to force it into a 
#   debugger.  Then you can do "puts page.body" to see what the page
#   is looking like.  This is necessary to tell what select2 is
#   generating as dynamic html (such as all the <li> items that are
#   the dropdowbn list), because if you just go to the browser and
#   do View Source you don't see all the dynamic select2 stuff.
#
# Since 1/19/2017 Derek Carlson <carlson.derek@gmail.com>
#############################################################################
RSpec.feature "Actions available from home page", 
  :type => :feature, js: true do

  include PropertySpecPageHelper  
  include StaticPagesSpecPageHelper
  let(:home_page) { StaticPagesSpecPageHelper::HomePageSpecPageHelper.new }

  before(:each) do
    FactoryGirl.create(:property, id: "10064", 
      address1: "653 Alameda St", streetname: "Alameda St")
    FactoryGirl.create(:property, id: "10002", 
      address1: "259 Acacia St", streetname: "Acacia St")
    FactoryGirl.create(:property, id: "16494", 
      address1: "1090 Rubio St", streetname: "Rubio St")
  end

  # 1 & 2 ####################################################################
  context "search for a property that exists in the database" do

    # 1 ######################################################################
    scenario "by using dropdown list" do
      
      home_page.visit_page.click_select2_item("1090 Rubio St").click_search
      expect(page).to show_property_at("1090 Rubio St")

    end  

    # 2 ######################################################################
    context "by typing directly into combobox" do
      
      scenario "an address spelled verbatim to the way it's spelled " +
        "in the database" do
          
        home_page.visit_page.
          type_text_for_existing_item_into_select2("259 Acacia St").click_search
        expect(page).to show_property_at("259 Acacia St")
        
      end

      scenario "an address spelled different from the way it's spelled " +
        "in the database" do
          
        home_page.visit_page.
          type_text_for_unlisted_item_into_select2(
            "259 ACACIA Street").click_search

        expect(page).to show_property_at("259 Acacia St")
        
      end
      
    end  
  end

  # 3 ########################################################################
  scenario "search for a property that doesn't exist in the database" do

      # Even though this test is for a property that doesn't exist, 
      # we still create a few properties in the before(:each) above
      # so that the select2 AJAX call proceeds as per usual and 
      # loads the dropdown list, because that can affect things even
      # when someone types an address into the search field that isn't one
      # of the addresses in the dropdown list.  Basically I want to set up
      # select2 state to mirror what it will be like in real production.

      home_page.visit_page.type_text_for_unlisted_item_into_select2(
        "1000 E Mount Curve Ave").click_search
      expect(page).to show_property_not_found("1000 E Mount Curve Ave")

  end

  # 4 ########################################################################
  scenario "search, when clicked with an empty select2, stays on homepage" do

    home_page.visit_page.click_search
    sleep 5 # TODO: Come up with better solution
    expect(page).to be_the_home_page

  end

end # feature

