class OrganismPart < ActiveRecord::Base
	has_many :bio_samples
end
