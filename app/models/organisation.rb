class Organisation < ActiveRecord::Base
	has_many :people
	has_many :bio_source_providers
end
