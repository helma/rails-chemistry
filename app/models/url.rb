class Url < ActiveRecord::Base
  has_one :protocol, :as => :document
  #has_many :generic_datas, :as => :source
end
