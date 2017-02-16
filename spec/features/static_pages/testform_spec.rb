require 'rails_helper'
require 'pry-byebug'

RSpec.feature "Actions available from testform page", :type => :feature, js: true do

  scenario "TEMP: Search for a property via the testform" do

    visit "/static_pages/testform"
    fill_in "id", :with => "653 Alameda St"
    
    fill_in "datalistdude", :with => "Altadena"
    
    find('#selectdude').find(:xpath, 'option[1]').select_option
    find('#selectdude').find("option[value='123']").click    

    expect(page).to have_css('div#testform-div-to-change')
    expect(page).to have_selector('div#testform-div-to-change', 
      text: "I have seen the light" )
    expect(page).to have_selector('div#testform-div-to-change', 
      text: /i have seen the light/i )
    
    # binding.pry
    
    sleep(2)
    click_button("Submit")
    
    expect(page).to have_text(/653 Alameda St/i)
    sleep(2)
    
  end 
  
end # feature
