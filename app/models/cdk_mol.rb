class CdkMol

  def initialize(smiles)

    @sp = Rjb::import('org.openscience.cdk.smiles.SmilesParser').new
    @sdg = Rjb::import('org.openscience.cdk.layout.StructureDiagramGenerator').new
    @out = Rjb::import('java.io.ByteArrayOutputStream').new
    @mol = @sp.parseSmiles(smiles)
    @sdg.setMolecule(@mol)
    @sdg.generateCoordinates()
    @mol = @sdg.getMolecule();

  end

  def jme_molfile

    @writer = Rjb::import('org.openscience.cdk.io.MDLWriter').new(@out)
    @writer.write(@mol)
    @molfile = @out.toString
    @molfile.gsub(/\$+/,'').chomp.gsub(/\n/,"|\n")

  end

end
