class BoolValue < ActiveRecord::Base
  has_many :generic_datas, :as => :value
end
