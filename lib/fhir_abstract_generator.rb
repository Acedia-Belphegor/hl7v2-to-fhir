require 'json'
require "base64"
require 'fhir_client'
require_relative 'message_parser'

Dir[File.expand_path(File.dirname(__FILE__)) << '/generate_*.rb'].each do |file|
    require file
end

class FhirAbstractGenerator    
    def initialize(params)
        @params = params
        str = if Encoding.find(params[:encoding]) == Encoding::ISO_2022_JP
            Base64.decode64(params[:message]).force_encoding(Encoding::ISO_2022_JP).encode("utf-8")
        else
            Base64.decode64(params[:message]).force_encoding("utf-8")
        end
        @message = MessageParser.new(str).to_simplify
        @error = validation
        @client = FHIR::Client.new("http://localhost:8080", default_format: 'json')
        @client.use_r4
        FHIR::Model.client = @client            
        @bundle = FHIR::Bundle.new
        @bundle.id = SecureRandom.uuid
        @bundle.type = :message
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
        { 
            message: @message, 
            bundle: @bundle, 
            params: @params 
        }
    end

    def has_error?()
        @error.present? || false
    end

    def get_error()
        @error
    end

    private
    def validation()
        raise NotImplementedError.new("You must implement #{self.class}##{__method__}")
    end
end