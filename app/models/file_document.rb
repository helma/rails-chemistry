class FileDocument < ActiveRecord::Base
  file_column :file#, :store_dir => "file_document/"
  has_one :protocol, :as => :document
  has_one :generic_data, :as => :value

  def to_label
    file
  end
end

