module BioSamplesHelper
  def affymetrix_file_column(record)
    name = '-'
    record.outputs.each do |o|
      name = o.file if o.class == FileDocument
    end
    link_to File.basename(name), name.gsub(/public\//,'')
  end
end
