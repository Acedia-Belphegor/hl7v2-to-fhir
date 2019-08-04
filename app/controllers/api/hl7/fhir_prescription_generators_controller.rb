# encoding: utf-8
require 'json'
require './lib/hl7fhir/fhir_prescription_generator'

class Api::Hl7::FhirPrescriptionGeneratorsController < ApplicationController
    def index
        # GET：HL7サンプルメッセージを返す
        raw_message = get_message_example()
        raw_message = raw_message.force_encoding("utf-8")
        parser = HL7Parser.new(raw_message)        
        render json: parser.get_parsed_message()
    end
  
    def create
        # POST：リクエストBODYに設定されたHL7v2メッセージをFHIR(json)形式に変換して返す
        raw_message = request.body.read
        generator = FhirPrescriptionGenerator.new(raw_message.force_encoding("utf-8"), generate: true)
        render json: generator.get_resource.to_json
    end
end