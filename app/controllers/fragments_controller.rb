class FragmentsController < ApplicationController

  require 'openbabel'

  def search
    # load current smarts
=begin
    unless params[:smarts].blank?
      begin
        mol = CdkMol.new(params[:smarts])
        @molfile = mol.jme_molfile
      rescue
        flash[:notice] = "Cannot process '" + params[:smarts] + "'!"
      end
    end
=end

    @endpoints = LazarModule.find(:all)
    match_smarts if params[:smarts]

  end

  def match_smarts

    flash[:warning] = ""
    pattern = OpenBabel::OBSmartsPattern.new
    flash[:warning] += "Cannot parse SMARTS \"#{smarts}\".\n" unless pattern.init(params[:smarts])
    lazar_module = LazarModule.find(params[:endpoint_id])

    # read new molecules
    smi = Dir["#{lazar_module.directory}/**/data/*.smi"][0]
    cl = smi.sub(/smi$/,"class")

    c=OpenBabel::OBConversion.new
    c.set_in_format 'smi'

    # smiles
    molecules = []
    File.open(smi).each do |l|
      l.chomp!
      items = l.split(/\t/)
      mol = OpenBabel::OBMol.new
      begin
        c.read_string mol, items[1]
        molecules << [items[0],items[1],mol]
      rescue
        flash[:warning] += "Cannot parse SMILES \"#{items[1]}\", compound id #{items[0]}.\n"
      end
    end

    # activities
    activities = {}
    File.open(cl).each do |l|
      l.chomp!
      items = l.split(/\t/)
      case items[2]
      when '1'
        activities[items[0]] = true
      when '0'
        activities[items[0]] = false
      end
    end

    # match fragment
    @matches = {}
    @matches["actives"] = []
    @matches["inactives"] = []
    @total_nr = {}
    @total_nr["actives"] = 0
    @total_nr["inactives"] = 0
    session[:page] = {}
    session[:page]["actives"] = {}
    session[:page]["inactives"] = {}

    # OPTIMIZE: avoid rematching of molecules during page reloads
    molecules.each do |m|
      if pattern.match(m[2],true)
        @matches["actives"] << m if activities[m[0]]
        @matches["inactives"] << m if !activities[m[0]]
      end
      @total_nr["actives"] +=1 if activities[m[0]]
      @total_nr["inactives"] +=1 if !activities[m[0]]
    end

    @smarts = params[:smarts]

    nf = @matches["actives"].size+@matches["inactives"].size
    n  = @total_nr["actives"]+@total_nr["inactives"]
    @ea = @total_nr["actives"]*nf/n; # expected actives
    @ei = @total_nr["inactives"]*nf/n; # expected inactives

		# chi square with Yate's correction
		# i.e. reduce observed frequencies by 0.5
		@chisq = (@matches["actives"].size-@ea-0.5)**2/@ea + (@matches["inactives"].size-@ei-0.5)**2/@ei;

    @activating = false
    @deactivating = false
    if @chisq > 3.84
      @activating = true if @matches["actives"].size > @ea
      @deactivating = true if @matches["inactives"].size > @ei
    end

    if params[:actives_page]
      session[:page]["actives"]["nr"] = params[:actives_page].to_i 
    else
      session[:page]["actives"]["nr"] = 0
    end

    if params[:inactives_page]
      session[:page]["inactives"]["nr"] = params[:inactives_page].to_i 
    else
      session[:page]["inactives"]["nr"] = 0
    end

    session[:page]["actives"]["size"] = @matches["actives"].size
    session[:page]["inactives"]["size"] = @matches["inactives"].size

    session[:page].each do |k,p|
      p["next"] = p["nr"] + 1
      p["prev"] = p["nr"] - 1
      p["start"] = 9 * (p["nr"] - 1)
      p["nr_pages"] = p["size"]/9
    end
  end

  # TODO: reload page to anchor
  # TODO: JME help

  def upload
    file = params[:file].original_filename
    activity = file.sub(/\..*$/,'')
    path = RAILS_ROOT + "/public/data/" + activity
    Dir.mkdir path
    datapath = path + "/data/"
    Dir.mkdir datapath
    basename = datapath + activity
    smi = File.open("#{basename}.smi","w")
    cl = File.open("#{basename}.class","w")
    params[:file].read.each do |line|
      items = line.split(/\s+/)
      smi.puts "#{items[0]}\t#{items[1]}"
      cl.puts "#{items[0]}\t#{activity}\t#{items[2]}"
    end
    if LazarCategory.find_by_name("Uploads").blank?
      cat = LazarCategory.create(:name => "Uploads")
    else
      cat = LazarCategory.find_by_name("Uploads")
    end
    LazarModule.create(:endpoint => activity, :directory => path, :lazar_category => cat)
    redirect_to :action => :search
  end

  
end
