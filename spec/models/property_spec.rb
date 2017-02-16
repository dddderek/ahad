require "rails_helper"

RSpec.describe Property, :type => :model do

  # Verify associations set up correctly, since at the moment the coverage
  # of these was removed from the view spec in favor of stubs for speed
  # and isolution.
  it "returns the apn parcel number if it exists" do
    apn = FactoryGirl.create(:apn, parcel: "5844-015-004")
    # 5844-015-004 is for 1090 Rubio St.
    @property = Property.find(apn.propid)          
    expect(@property.apn.parcel).to eq("5844-015-004")
  end

  it "returns the first photo if it exists" do
    photo = FactoryGirl.create(:photo, filename: "16494_photo_01.jpg")
    @property = Property.find(photo.propid)
    expect(@property.photos.first.filename).to eq("16494_photo_01.jpg")
  end

end