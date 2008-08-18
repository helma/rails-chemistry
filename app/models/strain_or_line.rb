class StrainOrLine < ActiveRecord::Base
	has_many :bio_samples
	belongs_to :organism
end
