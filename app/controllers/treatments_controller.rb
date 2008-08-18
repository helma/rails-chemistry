class TreatmentsController < ApplicationController
  active_scaffold :treatment do |conf|
    conf.columns = [:bio_sample, :compound, :dose, :duration, :solvent, :solvent_concentration, :protocols]
    conf.update.columns = [:bio_sample, :compound, :dose,:solvent, :protocols] # , :duration, :solvent_concentration
    conf.columns[:bio_sample].form_ui = :select
    conf.columns[:compound].form_ui = :select
    conf.columns[:solvent].form_ui = :select
    conf.columns[:protocols].form_ui = :select

    conf.columns[:dose].clear_link
    conf.columns[:duration].clear_link
    conf.columns[:solvent_concentration].clear_link

    conf.actions.exclude :show

    conf.update.link.page = true
    conf.create.link.page = true
  end

  private

	def authorize_write
		user = User.find(session[:user_id])
		if user.workpackages.blank?  
			flash[:notice] = 'Please login with your workpackage/group leader password:'
			redirect_to :controller => 'login', :action =>'login'
		end
	end
end
