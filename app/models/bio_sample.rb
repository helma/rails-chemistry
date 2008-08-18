class BioSample < ActiveRecord::Base
	belongs_to :bio_source_provider
	belongs_to :developmental_stage
	belongs_to :cell_line
	belongs_to :cell_type
	belongs_to :organism
	belongs_to :organism_part
	belongs_to :sex
	belongs_to :strain_or_line
  belongs_to :experiment
  has_and_belongs_to_many :protocols
  has_many :treatments
  #has_many :measurements, :class_name => "GenericData", :as => :sample
  has_many :generic_datas, :as => :sample
end
