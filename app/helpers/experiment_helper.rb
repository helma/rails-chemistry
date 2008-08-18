module ExperimentsHelper

  def protocols_and_software_column(record)
    record.protocols.each do |p|
      link_to p.name, :controller => :protocols, :action => :show, :id => p.id
    end
  end

  #def gene_expression_measurement_bio_sample_form_column(record, input_name)
  #end
end
