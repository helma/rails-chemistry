class BioSamplesController < ApplicationController

  before_filter :remove_empty_columns

  active_scaffold :bio_sample do |conf|

    #conf.actions.exclude :show
    conf.columns = [ "name", "bio_source_provider", "organism", "organism_part", "sex", "strain_or_line","individual_name", "developmental_stage", "cell_line", "cell_type", "growth_condition", :protocols ]
    conf.columns['individual_name'].label = "Individual"

    conf.columns['organism'].form_ui = :select
    conf.columns['organism_part'].form_ui = :select
    conf.columns['sex'].form_ui = :select
    conf.columns['strain_or_line'].form_ui = :select
    conf.columns['developmental_stage'].form_ui = :select
    conf.columns['cell_line'].form_ui = :select
    conf.columns['cell_type'].form_ui = :select
    conf.columns['protocols'].form_ui = :select
    #conf.columns['growth_condition'].form_ui = :select

    conf.list.per_page = 500

    conf.columns.each do |c|
      c.clear_link unless c == 'protocols'
    end

    conf.update.link.page = true
    conf.create.link.page = true

  end

  def remove_empty_columns
    [ "bio_source_provider_id", "organism_id", "organism_part_id", "sex_id", "strain_or_line_id","individual_name", "developmental_stage_id", "cell_line_id", "cell_type_id", "growth_condition" ].each do |c|
      if BioSample.count(c, :conditions => "experiment_id = #{session[:exp_id]} AND #{c} NOT NULL", :distinct => true) == 0 
        active_scaffold_config.list.columns.exclude c.gsub(/_id/,'')
      end
    end

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
