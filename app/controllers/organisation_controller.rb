class OrganisationController < ApplicationController
	active_scaffold :organisation do |conf|
    show.columns = [:name, :address, :people]
    conf.columns[:address].form_ui = :textarea
  end
end
