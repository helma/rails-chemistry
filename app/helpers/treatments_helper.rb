module TreatmentsHelper
  def dose_form_column(record, input_name)
    #record.dose.value
    #input_name.value
    text_field :record, :dose, :name => input_name
  end
end
