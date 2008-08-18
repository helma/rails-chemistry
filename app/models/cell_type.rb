class CellType < ActiveRecord::Base
	has_many :bio_samples
end
