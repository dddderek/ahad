require "rails_helper"

RSpec.describe StaticPagesController, :type => :controller do
  render_views

  # since controller does nothing at the moment, this
  # should go into a view test instead.
  describe "GET home" do
    it "displays the home page" do
      get :home
      expect(response.body).to match /Architectural Database/im
    end
  end
end
