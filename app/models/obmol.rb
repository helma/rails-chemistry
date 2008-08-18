class Obmol

  require 'openbabel'
  include OpenBabel

  def initialize(smi)

    @mol = OBMol.new
    @conv = OBConversion.new
    @pattern = OBSmartsPattern.new

    @smiles = smi
    @conv.set_in_format("smi")
    @conv.read_string(@mol, @smiles)  or raise "Can't parse SMILES #{@smiles}."
    #@mol.add_hydrogens
  end

  def molfile
    @conv.set_out_format("mol")
    @conv.write_string(@mol)#.strip
  end

  def nr_smarts(smarts)
    @pattern.init(smarts)
    @pattern.match(@mol)
    @pattern.get_umap_list.size
  end

  def matches_smarts?(smarts)
    @pattern.init(smarts)
    @pattern.match(@mol,true)
  end

  def logP
    logP = OBLogP.new
    logP.predict(@mol)
  end

end
