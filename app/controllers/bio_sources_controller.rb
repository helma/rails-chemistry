class BioSourcesController < ApplicationController
  active_scaffold :bio_source do |conf|
   show.columns = [ "name", "bio_source_provider", "individual", "developmental_stage", "cell_line", "cell_type", "organism", "organism_part", "sex", "strain_or_line" ]
  end
end
