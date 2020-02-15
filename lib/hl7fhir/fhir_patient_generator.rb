# encoding: UTF-8
require_relative 'fhir_abstract_generator'

class FhirPatientGenerator < FhirAbstractGenerator
    def perform()
        @bundle.entry.concat(GenerateMessageHeader.new(get_params).perform) # MessageHeader
        @bundle.entry.concat(GeneratePatient.new(get_params).perform) # Patient
        @bundle.entry.concat(GenerateRelatedPerson.new(get_params).perform) # RelatedPerson
        @bundle.entry.concat(GenerateObservation.new(get_params).perform) # Observation
        @bundle.entry.concat(GenerateAllergyIntolerance.new(get_params).perform) # AllergyIntolerance
        @bundle.entry.concat(GenerateCoverage.new(get_params).perform) # Coverage
    end

    private
    def validation()
        raise 'reject message, incorrect [MSH-9.MessageType]' unless validate_message_type('ADT','A08')
        true
    end
end