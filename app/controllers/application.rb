# You can define default settings (e.g. for login) by placing a custom application.rb in app/controllers 
class ApplicationController < ActionController::Base

	private

	def require_ssl
		if !request.ssl?
			redirect_to :protocol => "https://"
		end
	end

end
