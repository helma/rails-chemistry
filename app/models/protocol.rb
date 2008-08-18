class Protocol < ActiveRecord::Base
	has_and_belongs_to_many :experiments
	has_and_belongs_to_many :bio_samples
	has_and_belongs_to_many :treatments
	has_and_belongs_to_many :generic_datas
  belongs_to :workpackage
  belongs_to :document, :polymorphic => true

  def to_label
    label = ""
    case self.document_type
    when "FileDocument"
      label = File.basename(document.file)
    else
      label = document.name
    end
    label
  end

end
