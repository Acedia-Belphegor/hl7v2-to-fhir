# encoding: UTF-8
require_relative 'fhir_abstract_generator'
require_relative 'generate_abstract'

class FhirInjectionGenerator < FhirAbstractGenerator
    def perform()
        @bundle.entry.concat(GenerateMessageHeader.new(get_params).perform) # MessageHeader
        @bundle.entry.concat(GeneratePatient.new(get_params).perform) # Patient
        @bundle.entry.concat(GenerateCoverage.new(get_params).perform) # Coverage
        @bundle.entry.concat(GeneratePractitioner.new(get_params).perform) # Practitioner
        @bundle.entry.concat(GeneratePractitionerRole.new(get_params).perform) # PractitionerRole
        @bundle.entry.concat(GenerateOrganization.new(get_params).perform) # Organization
        @bundle.entry.concat(GenerateMedicationRequestInjection.new(get_params).perform) # MedicationRequest
    end

    private
    def validation()
        raise 'reject message, incorrect [MSH-9.MessageType]' unless validate_message_type('RDE','O11')
        true
    end
end