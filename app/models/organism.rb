class Organism < ActiveRecord::Base
	has_many :bio_samples

  def to_label
    genus + ' ' + species + ' (' + name + ')'
  end
end
