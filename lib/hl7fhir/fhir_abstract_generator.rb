# encoding: UTF-8
require 'json'
require 'fhir_client'
require_relative '../hl7v2/hl7parser'
Dir[File.expand_path(File.dirname(__FILE__)) << '/generate_*.rb'].each do |file|
    require file
end

class FhirAbstractGenerator
    attr_accessor :parser
    
    def initialize(raw_message, generate: false)
        @parser = HL7Parser.new(raw_message)
        validation
        @client = FHIR::Client.new("http://localhost:8080", default_format: 'json')
        @client.use_r4
        FHIR::Model.client = @client            
        @bundle = FHIR::Bundle.new
        @bundle.type = 'message'
        perform if generate
    end

    def perform()
        raise NotImplementedError.new("You must implement #{self.class}##{__method__}")
    end

    def get_resources()
        @bundle
    end

    def get_resources_from_type(resource_type)
        @bundle.entry.select{ |c| c.resource.resourceType == resource_type }
    end

    def get_params()
        { parser: @parser, bundle: @bundle }
    end

    private
    def validation()
        raise NotImplementedError.new("You must implement #{self.class}##{__method__}")
    end

    def validate_message_type(message_code, trigger_event)
        @parser.get_parsed_fields('MSH','Message Type').each do |field|
            field['array_data'].first.select{ |c| ["Message Code","Trigger Event"].include?(c['name']) }.each do |element|
                case element['name']
                when 'Message Code'
                    return false unless element['value'] == message_code
                when 'Trigger Event'
                    return false unless element['value'] == trigger_event
                end
            end
        end
        true
    end
end