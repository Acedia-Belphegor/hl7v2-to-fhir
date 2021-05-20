require './lib/fhir_injection_generator'

class Api::Hl7::FhirInjectionGeneratorsController < ApplicationController
  # POST：リクエストBODYに設定されたHL7v2メッセージをFHIR(json/xml)形式に変換して返す
  def create
    generator = FhirInjectionGenerator.new(permitted_params)
    if generator.has_error?
      render json: { type: "injection", errors: [generator.get_error] }, status: :bad_request and return
    end
    generator.perform
    respond_to do |format|
      format.json { render :json => generator.to_json }
      format.xml  { render :xml => generator.to_xml }
    end
  end

  def permitted_params
    params.require(:fhir_abstract_generator).permit(
      :encoding,
      :prefecture_code,
      :medical_fee_point_code,
      :medical_institution_code,
      :message
    )
  end
end