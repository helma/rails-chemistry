class TextDocument < ActiveRecord::Base
  has_one :protocol, :as => :document
end
