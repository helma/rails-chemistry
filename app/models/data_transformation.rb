# Aggregated results derived from treatment measurements and/or transformed data
# special cases:
# no inputs: aggregated literature/database results without initial measurements

class DataTransformation  < ActiveRecord::Base
  has_and_belongs_to_many :generic_datas
  has_and_belongs_to_many :protocols
  belongs_to :result, :class_name => "GenericData", :foreign_key => :result_id
  belongs_to :experiment
end
