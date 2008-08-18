module ProtocolsHelper

  def document_column(record)
    case record.document_type
    when "FileDocument"
      @file_doc = record.document
      link_to File.basename(record.document.file), url_for_file_column('file_doc', 'file')
    when "Url"
      link_to record.document.name, record.document.name, :target => '_blank'
    when "TextDocument"
      link_to record.document.name, :controller => :text_documents, :action => :show, :id => record.document.id, :target => '_blank'
    when "BibliographicReference"
      link_to record.document.name, :controller => :bibliographic_references, :action => :show, :id => record.document.id, :target => '_blank'
    end
  end

end
