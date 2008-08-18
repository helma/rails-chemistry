class StringValue < ActiveRecord::Base
  has_one :generic_data, :as => :value
  def to_label
    value
  end
end

