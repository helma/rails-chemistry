class FloatValue < ActiveRecord::Base
  has_one :generic_data, :as => :value

  def to_label
    value.to_s
  end
end
