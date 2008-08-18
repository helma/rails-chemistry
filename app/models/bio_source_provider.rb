class BioSourceProvider < ActiveRecord::Base
	has_many :bio_samples
	#belongs_to :person
	belongs_to :organisation

  def to_label
    organisation.name
  end

  def name
    organisation.name
  end

end
