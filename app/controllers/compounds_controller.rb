class CompoundsController < ApplicationController

  require 'rjb'

	active_scaffold :compound do |conf|

    # general
    conf.action_links.add :list, :label => 'Training compounds', :type => :table, :parameters => {:show => 'training_set'}, :page => true
    conf.action_links.add :list, :label => 'All compounds', :type => :table, :parameters => {:show => 'all'}, :page => true
		conf.actions.add :show

    conf.columns.add :chemid

		conf.columns[:cas].label = 'CAS'
		conf.columns[:smiles].label = '2D Structure'
		conf.columns[:chemid].label = 'External Data'

    columns[:cas].set_link('show', :page => true)
    columns[:name].set_link('show', :page => true)

    # list
		conf.list.per_page = 15 
		conf.list.sorting = {:name => 'ASC'}
		conf.list.columns = [:cas, :name]

    # show
    conf.show.link.page = true
		show.columns = [:cas, :smiles, :comment, :chemid]#, :datas, :sensitiser

    # update
    conf.update.link.page = true
    conf.update.columns = [:name, :cas, :smiles, :comment]

    # create
    conf.create.link.page = true
    conf.create.columns = [:name, :cas, :smiles, :comment]

	end

  def index
    if params[:id].blank?
      redirect_to :action => 'list'
    else
      redirect_to :action => 'show', :id => params[:id]
    end
  end

  def validation
    @failed = []
    Compound.find(:all).each do |c|
      failures = ''
      if c.cas.blank?
        failures << "CAS Nr. missing<br/>" 
      else
        failures << "Invalid CAS Nr.<br/>" unless c.cas_valid?
      end
      if c.smiles.blank?
        failures << "Structure missing<br/>" 
      else
        failures << "Invalid Smiles structure<br/>" unless c.smiles_valid?
      end
=begin
      unless c.cas.blank? or c.smiles.blank?
        cids = c.get_cid_from_smiles
        failures << "CAS non-unique" unless cids.size == 1
      end
=end

      #if c.inchi.blank?
        #failures << "InChi missing<br/>" 
      #end
      unless failures.blank?
        @failed << [c.cas,c.name,failures,c.id]
      end
    end
  end

  def conditions_for_collection
    if params[:show] == 'training_set'
      training_ids = SensitivTrainingCompound.find(:all, :select => :compound_id).map(&:compound_id)
      ['id IN (?)', training_ids]
    end
  end

  def display_smiles_with_fragments
    
    # sanitize smiles
    smiles = params[:smiles].chomp.gsub(/\s+/,'')
    display = Rjb::import('DisplayStructure').new

    # TODO: display unknown fragments
    image = display.displaySubstructureP(smiles,session[:activating_fragments],session[:deactivating_fragments],session[:unknown_fragments], session[:activating_p], session[:deactivating_p])
    out=Rjb::import('java.io.ByteArrayOutputStream').new
    Rjb::import('javax.imageio.ImageIO').write(image, "png", out)

    send_data(out.toByteArray, :type => "image/png", :disposition => "inline", :filename => "molecule.png")

	end

	def display_smiles

    # sanitize smiles
    smiles = params[:smiles].chomp.gsub(/\s+/,'')
    display = Rjb::import('DisplayStructure').new
    image = display.displaySmiles(smiles)
    if image
      out=Rjb::import('java.io.ByteArrayOutputStream').new
      Rjb::import('javax.imageio.ImageIO').write(image, "png", out)
      send_data(out.toByteArray, :type => "image/png", :disposition => "inline", :filename => "molecule.png")
    else
      "Cannot display \"#{smiles}\""
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
