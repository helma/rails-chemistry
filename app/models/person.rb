class Person < ActiveRecord::Base
	#validates_presence_of :email, :last_name
	has_and_belongs_to_many :experiments
	has_and_belongs_to_many :roles
	belongs_to :organisation
	has_one :bio_source_provider

	def to_label
    name = ''
    if !first_name.blank?
      name = first_name + ' '
    end
    if !last_name.blank?
      name = name + last_name
    end
    name
	end
end
