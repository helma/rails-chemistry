class Compound < ActiveRecord::Base

  require 'openbabel'

  has_and_belongs_to_many :experiments
  has_one :sensitiv_training_compound
  has_many :treatments
  has_many :treatments, :as => :solvent
  #has_many :measurements, :class_name => "GenericData", :as => :sample
  has_many :generic_datas, :as => :sample

  def treatments
    Treatment.find(:all, :conditions => "compound_id = #{self.id}")
  end

  def data_transformations
    results = []
    treatments.each do |t|
      t.generic_datas.each do |d|
        d.data_transformations.each do |t|
          results << t.result
        end
      end
    end
    results.uniq
  end

  def create_inchi

    begin
      c=OpenBabel::OBConversion.new
      c.set_in_and_out_formats 'smi', 'inchi'
      mol = OpenBabel::OBMol.new
      c.read_string(mol, smiles) or raise "Can't parse SMILES #{smiles}."
      inchi = c.write_string(mol).strip
      save!
    rescue
      puts "Cannot parse SMILES #{self.smiles}"
    end

  end

  def duplicates
    Compound.find_all_by_inchi(inchi).delete_if { |s| s == self }
  end

  # check if smiles is accepted by Openbabel
  def smiles_valid?
    begin
      c=OpenBabel::OBConversion.new
      c.set_in_format 'smi'
      mol = OpenBabel::OBMol.new
      true if c.read_string(mol, smiles)
    rescue
      false
    end
  end

  # check cas checksum
  def cas_valid?
    check_digit = cas.sub(/^\d+-\d+-/,'').to_i
    digits = cas.sub(/-\d$/,'').gsub(/-/,'')
    i = 1
    sum = 0
    digits.reverse.split("").each do |d|
      sum += d.to_i*i
      i += 1
    end
    sum.modulo(10) == check_digit
  end

  def get_cid_from_cas
    cids = get_cid(cas)
    if cids.size == 1
      self.cid = cids[0]
    else
      print "#{cids.size} Pubchem CIDs found for CAS #{cas}:"
      cids.each { |i| print " #{i}" }
      puts
    end
  end

  def get_cid_from_inchi
    get_cid(inchi)
  end

  def get_cid_from_smiles
    get_cid(smiles)
  end

  def get_pubchem_inchi
  end

  def get_pubchem_smiles
  end

  private

  def get_cid(term)
    require 'mechanize'
    agent = WWW::Mechanize.new
    page = agent.get "http://www.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pccompound&email=helma@in-silico.de&retmax=100&term=#{term}"

    cids = Array.new
    cids = (page.parser/"id").collect {|id| id.innerHTML}
    cids
  end

end
