class Workpackage < ActiveRecord::Base
  #has_and_belongs_to_many :protocols
  has_many :protocols
  has_many :experiments
	has_and_belongs_to_many :users
  
	def name
		nr.to_s
	end

end
