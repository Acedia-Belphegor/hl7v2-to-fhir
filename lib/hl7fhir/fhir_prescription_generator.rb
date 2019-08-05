# encoding: UTF-8
require 'json'
require 'fhir_client'
require_relative '../hl7v2/hl7parser'
Dir[File.expand_path(File.dirname(__FILE__)) << '/generate_*.rb'].each do |file|
    require file
end

class FhirPrescriptionGenerator
    def initialize(raw_message, generate: false)
        @parser = HL7Parser.new(raw_message)
        @client = FHIR::Client.new("http://localhost:8080", default_format: 'json')
        @client.use_r4()
        FHIR::Model.client = @client
        perform() if generate
    end

    def perform()
        @bundle = FHIR::Bundle.new()
        @bundle.type = 'message'
        @bundle.entry.concat(GenerateMessageHeader.new(@parser).perform) # MessageHeader
        @bundle.entry.concat(GeneratePatient.new(@parser).perform) # Patient
        @bundle.entry.concat(GeneratePractitioner.new(@parser).perform) # Practitioner
        @bundle.entry.concat(GeneratePractitionerRole.new(@parser).perform) # PractitionerRole
        @bundle.entry.concat(GenerateOrganization.new(@parser).perform) # Organization
        @bundle.entry.concat(GenerateMedicationRequest.new(@parser).perform) # MedicationRequest
        @bundle.entry.concat(GenerateCoverage.new(@parser).perform) # Coverage
    end

    def get_resource()
        return @bundle
    end
end

# test
generator = FhirPrescriptionGenerator.new(get_message_example, generate: true)
puts generator.get_resource.to_json