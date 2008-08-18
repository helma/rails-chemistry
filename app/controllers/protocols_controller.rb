class ProtocolsController < ApplicationController

  active_scaffold :protocol do |conf|

    conf.list.per_page = 50
    conf.actions.exclude :show

		conf.columns[:workpackage].form_ui = :select
		conf.columns[:description].form_ui = :textarea
    conf.columns[:description].options = { :cols => 95}

    columns[:workpackage].label = "WP"
    columns[:audited].label = "Approved by WP leader"
    list.columns = ["workpackage","document","description", "audited"]
    list.sorting = [{:workpackage_id => :asc}]
    create.columns = ["workpackage","description"]
    update.columns = ["workpackage","description"]

    create.link.page = true
    update.link.page = true
  end

  def edit
    session[:exp_id] = nil if params["parent_model"].blank? 
    @protocol = Protocol.find(params[:id])
    render :action => 'update'
  end

  def new
    session[:exp_id] = nil if params["parent_model"].blank? 
    @protocol = Protocol.new
    render :action => 'update'
  end

  def save

    if params[:id].blank?
      @protocol = Protocol.new
      if !params[:document][:text].blank? 
        @protocol.update_attribute(:document, TextDocument.new)
      elsif !params[:document][:name].blank?
        @protocol.update_attribute(:document, Url.new)
      elsif !params[:document][:file].blank?
        @protocol.update_attribute(:document, FileDocument.new)
      else
        # raise error
      end
    else
      @protocol = Protocol.find(params[:id])
    end

    @protocol.update_attribute(:description, params[:protocol][:description])
    @protocol.update_attribute(:workpackage_id, params[:protocol][:workpackage_id])

    case @protocol.document_type
    when "TextDocument"
      @protocol.document.update_attribute(:text, params[:document][:text])
      @protocol.document.update_attribute(:name, params[:document][:name])
    when "Url"
      @protocol.document.update_attribute(:name, params[:document][:name])
    when "FileDocument"
      @protocol.document.update_attribute(:file, params[:document][:file])
    end

    unless session[:exp_id].blank?
      @protocol.experiments << Experiment.find(session[:exp_id])
    end

    user = User.find(session[:user_id])
    if user.name =~ /wp.*_leader/
      user.workpackages.each do |w|
        @protocol.audited = true if @protocol.workpackage == w
      end
      @protocol.save
    end

    if params[:experiment_id].blank?
      redirect_to :action => :list, :id => @protocol.id
    else
      redirect_to :controller => :experiments, :action => :list
    end

  end

  def audit
		user = User.find(session[:user_id])
    protocol = Protocol.find(params[:id])
    correct_user = false

    if user.name =~ /wp.*_leader/
      user.workpackages.each do |w|
        correct_user = true if protocol.workpackage == w
      end
    end

    if correct_user
      protocol.audited = true 
      protocol.save
      redirect_to :action => :list, :id => protocol.id
    else
			flash[:notice] = "Please login with your workpackage leader password for WP#{protocol.workpackage.nr}:"
			redirect_to :controller => 'login', :action =>'login', :workpackage_id => protocol.workpackage.id
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

  def clear_experiment_id
    session[:exp_id] = nil
  end
end
