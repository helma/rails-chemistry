# This class associates measurements (raw generic_data) with bio_samples and compounds
# Special cases:
# bio_samples without compound: biocharacteristics experiments, negative controls
# compounds without bio_ѕamples: physical/chemical measurements

class Treatment  < ActiveRecord::Base
  belongs_to :compound
  belongs_to :bio_sample
  belongs_to :experiment
  belongs_to :dose, :class_name => "GenericData", :foreign_key => :dose_id
  belongs_to :duration, :class_name => "GenericData", :foreign_key => :duration_id
  belongs_to :solvent, :class_name => "Compound", :foreign_key => :solvent_id
  belongs_to :solvent_concentration, :class_name => "GenericData", :foreign_key => :solvent_concentration_id
  has_and_belongs_to_many :protocols
  has_many :generic_datas, :as => :sample

  def to_label
    label = ''
    begin
      if bio_sample
        label += "BioSample: "
        if bio_sample.name
          label += bio_sample.name
        elsif bio_sample.organism and bio_sample.organism_part
          label += bio_sample.organism.name.capitalize + " " + bio_sample.organism_part.name 
        else
          label = bio_sample.id.to_s
        end
      end
      if compound
        label += "<br/>" unless label.blank?
        label += "Compound: " + compound.name
      end
      if solvent
        label += "<br/>" unless label.blank?
        label += "Solvent: " + solvent.name
      end
    rescue
    end
    label
  end

end
