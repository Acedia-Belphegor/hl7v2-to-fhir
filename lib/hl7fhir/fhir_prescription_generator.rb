# encoding: UTF-8
require_relative 'fhir_abstract_generator'

class FhirPrescriptionGenerator < FhirAbstractGenerator
    def perform()
        @bundle.entry.concat(GenerateMessageHeader.new(get_params).perform) # MessageHeader
        @bundle.entry.concat(GeneratePatient.new(get_params).perform) # Patient
        @bundle.entry.concat(GenerateCoverage.new(get_params).perform) # Coverage
        @bundle.entry.concat(GeneratePractitioner.new(get_params).perform) # Practitioner
        @bundle.entry.concat(GeneratePractitionerRole.new(get_params).perform) # PractitionerRole
        @bundle.entry.concat(GenerateOrganization.new(get_params).perform) # Organization
        @bundle.entry.concat(GenerateMedicationRequest.new(get_params).perform) # MedicationRequest
    end

    private
    def validation()
        raise 'reject message, incorrect [MSH-9.MessageType]' if !validate_message_type('RDE','O11')
        true
    end
end

# test
generator = FhirPrescriptionGenerator.new(get_message_example('RDE'), generate: true)
puts generator.get_resources.to_json