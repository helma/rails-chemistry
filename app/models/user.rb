require 'digest/md5'
class User < ActiveRecord::Base

	has_and_belongs_to_many :workpackages

	def validate
		errors.add_to_base('Missing password') if hashed_password.blank?
	end

	def self.authenticate(name,password)
		user = self.find_by_name(name)
		if user
			expected_password = encrypted_password(password)
			if user.hashed_password != expected_password
				user = nil
			end
		end
		user
	end

	def self.authenticate_with_wp(name,password,wp_id)
    wp = Workpackage.find(wp_id)
		user = self.find_by_name(name)
		if user
			expected_password = encrypted_password(password)
			if user.hashed_password != expected_password
				user = nil
			end
      correct_wp = false
      user.workpackages.each do |w|
        correct_wp = true if wp = w
      end
      user = nil unless correct_wp
		end
		user
	end

	private

	def self.encrypted_password(password)
		Digest::MD5.hexdigest(password)
	end

end

