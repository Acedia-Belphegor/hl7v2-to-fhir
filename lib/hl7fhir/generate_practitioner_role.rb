# encoding: UTF-8
require_relative 'generate_abstract'

class GeneratePractitionerRole < GenerateAbstract
    def perform()
        practitioner_role = FHIR::PractitionerRole.new()

        orc_segment = @parser.get_parsed_segments('ORC')
        if orc_segment.nil? then
            return
        end
        
        orc_segment.first.select{|c| 
            Array[
                "Ordering Provider",
                "Entering Organization"
            ].include?(c['name'])
        }.each do |field|
            if ignore_fields?(field) then
                next
            end
            case field['name']
            when 'Ordering Provider' then
                # ORC-12.依頼者
                field['array_data'].first.select{|c|
                    Array[
                        "ID Number",
                    ]
                }.each do |element|
                    case element['name']
                    when 'ID Number' then
                        # 医師ID
                        identifier = FHIR::Identifier.new()
                        identifier.system = "OID:1.2.392.100495.20.3.41.1#{@parser.get_sending_facility[:all]}"
                        identifier.value = element['value']
                        practitioner_role.identifier = identifier

                        codeable_concept = FHIR::CodeableConcept.new()
                        coding = FHIR::Coding.new()
                        coding.code = 'doctor'
                        coding.system = 'http://terminology.hl7.org/CodeSystem/practitioner-role'
                        coding.display = 'Doctor'
                        codeable_concept.coding = coding
                        practitioner_role.code = codeable_concept                        

                        practitioner = get_resources_from_identifier('Practitioner', identifier)
                        if !practitioner.empty? then
                            reference = FHIR::Reference.new()
                            reference.type = practitioner.first.resource.resourceType
                            reference.identifier = practitioner.first.resource.identifier
                            practitioner_role.practitioner = reference
                        end
                    end
                end
            when 'Entering Organization' then
                # ORC-17.入力組織
                practitioner_role.specialty.push(get_codeable_concept(field['array_data'].first))
            end
        end
        entry = FHIR::Bundle::Entry.new()
        entry.resource = practitioner_role
        return Array[entry]
    end
end