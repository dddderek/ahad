#############################################################################
# module PropertySpecPageHelper
#
# Abstracts away all css-specific capybara commands for spec'ing the
# various pages of the Properties controller.
#
# Since 1/19/2017 Derek Carlson <carlson.derek@gmail.com>
#############################################################################
module PropertySpecPageHelper

  # CSS that confirms that the property page for the specified address
  # is showing.
  def show_property_at(addr)
    have_css("#ps-addr-title-zoom__text", :text => /#{addr}/i, :wait => 5)
  end
  
  # CSS that confirms that the "property not found" page is showing.
  def show_property_not_found(stuff)
    have_css("#pnf-explanation", :text => /#{stuff}/i, :wait => 5)
  end
  
end

RSpec.configure do |config|
  config.include PropertySpecPageHelper, :type => :feature
end
