class BibliographicReference < ActiveRecord::Base
  
  has_one :protocol, :as => :document
  #has_many :generic_datas, :as => :source

  def name
    text
  end
end

