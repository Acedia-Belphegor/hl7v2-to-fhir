# encoding: UTF-8
require_relative 'fhir_abstract_generator'

class FhirInspectionResultGenerator < FhirAbstractGenerator
    def perform()
        @bundle.entry.concat(GenerateMessageHeader.new(get_params).perform) # MessageHeader
        @bundle.entry.concat(GeneratePatient.new(get_params).perform) # Patient
        @bundle.entry.concat(GeneratePractitioner.new(get_params).perform) # Practitioner
        @bundle.entry.concat(GeneratePractitionerRole.new(get_params).perform) # PractitionerRole
        @bundle.entry.concat(GenerateOrganization.new(get_params).perform) # Organization
        @bundle.entry.concat(GenerateSpecimenContained.new(get_params).perform) # Specimen
        # @bundle.entry.concat(GenerateSpecimen.new(get_params).perform) # Specimen
        # @bundle.entry.concat(GenerateObservation.new(get_params).perform) # Observation
    end

    private
    def validation()
        raise 'reject message, incorrect [MSH-9.MessageType]' unless validate_message_type('OUL','R22') || validate_message_type('ORU','R01')
        true
    end
end