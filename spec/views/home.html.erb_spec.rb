require "rails_helper"

RSpec.describe "static_pages/home" do

  it "displays a search button" do
      render # knows what to render from "static_pages/home" above
      expect(rendered).to match /search/i
  end
  
end

