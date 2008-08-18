class PeopleController < ApplicationController
	active_scaffold :person do |conf|
		conf.label = 'Investigators'
    conf.actions.exclude :show
		conf.columns.exclude :bio_source_provider
    conf.columns[:roles].clear_link
    conf.columns[:roles].form_ui = :select
    #conf.subform.columns.add :roles

    conf.update.link.page = true
    conf.create.link.page = true
	end

  private
	def authorize_write
		user = User.find(session[:user_id])
		if user.workpackages.blank? || user.workpackage.nr == nil
			flash[:notice] = 'Please login with your workpackage/group leader password:'
			redirect_to :controller => 'login', :action =>'login'
		end
	end
end
