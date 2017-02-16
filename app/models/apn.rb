class Apn < ActiveRecord::Base
  belongs_to  :property, foreign_key: :propid #, optional: true,
  # Note: Above, sometimes 'optional: true' gets around a
  # gotcha, as per:
  # http://stackoverflow.com/questions/38983666/
  #   validation-failed-class-must-exist
  #   (search for answer containing: "belongs_to :city, optional: true")
  #
  # Was having an issue with FactoryGirl trying to create either
  # a property or an apn and it was failing... the
  # optional: true solved that issue.  However, I changed the
  # design and it was no longer necessary, so it's commented
  # out.  1/15/17 DDC
  self.table_name = "apn"
  
end