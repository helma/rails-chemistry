class ExperimentsController < ApplicationController

  before_filter :set_experiment_id, :only => :nested

	active_scaffold :experiment do |conf|

    conf.actions.exclude :show
    columns[:workpackage].label = "WP"
		columns[:people].label = 'Investigators'
    columns[:audited].label = "Approved by WP leader"
		conf.columns[:workpackage].form_ui = :select
		conf.columns[:protocols].form_ui = :select
		conf.columns[:title].form_ui = :textarea
    conf.columns[:title].options = { :cols => 95}
		conf.columns[:description].form_ui = :textarea
    conf.columns[:description].options = {:cols => 95 }
    conf.columns[:protocols].search_sql = "protocols.name"

		list.columns = [:workpackage, :title, :description, :date, :audited]
    list.sorting = [{:workpackage_id => :asc}]

		conf.nested.add_link("Investigators", [:people])
		#conf.nested.add_link("Protocols", [:protocols])
		conf.nested.add_link("Samples", [:bio_samples])
		conf.nested.add_link("Compounds", [:compounds])
		conf.nested.add_link("Treatments", [:treatments])
		conf.nested.add_link("Measurements", [:generic_datas])

    # create
    conf.create.link.page = true
		create.columns = [:workpackage, :title, :description, :date]

    # update
    conf.update.link.page = true
		update.columns = [:workpackage, :title, :description, :date]

	end

  def audit
		user = User.find(session[:user_id])
    experiment = Experiment.find(params[:id])
    correct_user = false

    if user.name =~ /wp.*_leader/
      user.workpackages.each do |w|
        correct_user = true if experiment.workpackage == w
      end
    end

    if correct_user
      experiment.audited = true 
      experiment.save
      redirect_to :action => :list, :id => experiment.id
    else
			flash[:notice] = "Please login with your workpackage leader password for WP#{experiment.workpackage.nr}:"
			redirect_to :controller => 'login', :action =>'login', :workpackage_id => experiment.workpackage.id
		end

  end

  private 

  def set_experiment_id
    session[:exp_id] = params[:id]
  end

	def authorize_write
		user = User.find(session[:user_id])
		if user.workpackages.blank? 
			flash[:notice] = 'Please login with your workpackage/group leader password:'
			redirect_to :controller => 'login', :action =>'login'
		end
	end

end
