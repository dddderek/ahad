class StaticPagesController < ApplicationController
  include PropertiesHelper
  
  def home
  end

  def help
  end
  
  def testform
  end
  
  # Search for a property based on ID or an address.  Addresses of various
  # forms (e.g. St, St., Street, etc.) will be normalized, if possible,
  # into the format for addresses in the database (see the normalize_address
  # routine for details).
  #
  # @param params[:id] [Integer or String] either the id of a property in
  #   the database or an actual street address (without city, state, zip)
  #
  # Will either redirect to the property#show page for a found property,
  # or will be redirected to a "Property Not Found" page.
  def search
    if (params[:id] =~ /^\d+$/)
      redirect_to "/properties/" + params[:id]
    else
      @property = Property.find_by_loose_address(params[:id])

      if @property != nil
        redirect_to "/properties/" + @property.id.to_s
      else
        @address = params[:id]
        render "properties/search_not_found"        
      end
    end
  end
  
end
