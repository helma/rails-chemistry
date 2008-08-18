class Experiment < ActiveRecord::Base

	has_and_belongs_to_many :experiment_designs
	has_and_belongs_to_many :people
	has_and_belongs_to_many :protocols
  has_and_belongs_to_many :compounds
	has_many :treatments
	has_many :bio_samples
  has_many :generic_datas
  belongs_to :workpackage

end
