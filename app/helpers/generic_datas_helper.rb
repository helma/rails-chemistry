module GenericDatasHelper

  def value_column(record)
    case record.value.class.to_s
    when "FileDocument"
      @file_doc = record.value
      link_to File.basename(record.value.file), url_for_file_column('file_doc', 'file')
    else
      record.to_label
    end
  end

  def sample_column(record)
    case record.sample.class.to_s
    when "Compound"
      link_to record.sample.to_label, :controller => :compounds, :action => :show, :id => record.sample.id
    when "BioSample"
      link_to record.sample.to_label, :controller => :bio_samples, :action => :show, :id => record.sample.id
    when "Treatment"
      link_to record.sample.to_label, :controller => :treatments, :action => :show, :id => record.sample.id
    else
      record.sample.to_label if record.sample
    end
  end

end
