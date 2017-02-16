require "spec_helper"

describe "routes" do
  it "routes / to the static_pages controller home action" do
    expect(:get => "/").to route_to(
      :controller => "static_pages", :action => "home")   
  end
end
