# encoding: utf-8
require 'json'
require './lib/hl7fhir/fhir_patient_generator'

class Api::Hl7::FhirPatientGeneratorsController < ApplicationController
    # GET：HL7サンプルメッセージを返す
    def index        
        parse(get_message_example('ADT'))
    end
  
    # POST：リクエストBODYに設定されたHL7v2メッセージをFHIR(json/xml)形式に変換して返す
    def create        
        parse(request.body.read)
    end

    def parse(raw_message)
        generator = FhirPatientGenerator.new(raw_message.force_encoding("utf-8"), generate: true)
        respond_to do |format|
            format.json { render :json => generator.get_resources.to_json }
            format.xml  { render :xml => generator.get_resources.to_xml }
        end
    end
end