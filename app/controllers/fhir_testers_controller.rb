require "base64"
require './lib/fhir_prescription_generator'
require './lib/fhir_injection_generator'
require './lib/fhir_inspection_result_generator'

class FhirTestersController < ApplicationController
  def index
    render "index"
  end

  def create
    generator = case params[:type]
                when 'prescription'
                  FhirPrescriptionGenerator.new(permitted_params)
                when 'injection'
                  FhirInjectionGenerator.new(permitted_params)
                when 'inspection_result'
                  FhirInspectionResultGenerator.new(permitted_params)
                end

    if generator.has_error?
      render json: { type: params[:type], errors: [generator.get_error] }, status: :bad_request and return
    end

    generator.perform
        
    if params[:format] == 'xml'
      render xml: generator.to_xml
    else
      render json: generator.to_json
    end
  end

  def permitted_params()
    {
      encoding: "UTF-8",
      prefecture_code: "13",
      medical_fee_point_code: "1",
      medical_institution_code: "9999999",
      message: Base64.encode64(params[:data])
    }
  end
end