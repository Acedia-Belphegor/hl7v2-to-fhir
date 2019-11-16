# encoding: UTF-8
require_relative 'fhir_abstract_generator'
require_relative 'generate_abstract'

class FhirPrescriptionGenerator < FhirAbstractGenerator
    def perform()
        @bundle.entry.concat(GenerateMessageHeader.new(get_params).perform) # MessageHeader
        @bundle.entry.concat(GeneratePatient.new(get_params).perform) # Patient
        @bundle.entry.concat(GenerateCoverage.new(get_params).perform) # Coverage
        @bundle.entry.concat(GeneratePractitioner.new(get_params).perform) # Practitioner
        @bundle.entry.concat(GeneratePractitionerRole.new(get_params).perform) # PractitionerRole
        @bundle.entry.concat(GenerateOrganization.new(get_params).perform) # Organization
        @bundle.entry.concat(GenerateMedicationRequest.new(get_params).perform) # MedicationRequest
        # @bundle.entry.concat(GenerateServiceRequest.new(get_params).perform) # ServiceRequest
    end

    private
    def validation()
        raise 'reject message, incorrect [MSH-9.MessageType]' if !validate_message_type('RDE','O11')
        true
    end
end

class GenerateServiceRequest < GenerateAbstract
    def perform()
        service_request = FHIR::ServiceRequest.new()

        rxe_segment = @parser.get_parsed_segments('RXE')
        if rxe_segment.nil? then
            return
        end
        rxe_segment.first.select{|c|
            Array[
                "Pharmacy/Treatment Supplier's Special Dispensing Instructions",
            ].include?(c['name'])            
        }.each do |field|
            if ignore_fields?(field) then
                next
            end
            case field['name']
            when "Pharmacy/Treatment Supplier's Special Dispensing Instructions" then
                # RXE-21.薬剤部門/治療部門による特別な調剤指示
                field['array_data'].each do |record|
                    service_request.category.push(generate_codeable_concept(record))
                end
            end
        end
        # 投薬要求の参照
        get_resources_from_type('MedicationRequest').each do |entry|
            service_request.basedOn.push(create_reference(entry))
        end
        entry = FHIR::Bundle::Entry.new()
        entry.resource = service_request
        return Array[entry]
    end
end