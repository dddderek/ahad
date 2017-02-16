class Photo < ActiveRecord::Base
  belongs_to  :property, foreign_key: :propid
  
end