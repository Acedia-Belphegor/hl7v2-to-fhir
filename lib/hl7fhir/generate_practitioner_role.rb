# encoding: UTF-8
require_relative 'generate_abstract'

class GeneratePractitionerRole < GenerateAbstract
    def perform()
        practitioner_role = FHIR::PractitionerRole.new
        practitioner_role.id = SecureRandom.uuid

        orc_segment = @parser.get_parsed_segments('ORC')
        return if orc_segment.nil?
        
        orc_segment.first.select{ |c| ["Ordering Provider","Entering Organization"].include?(c['name']) }.each do |field|
            next if ignore_fields?(field)
            case field['name']
            when 'Ordering Provider'
                # ORC-12.依頼者
                field['array_data'].first.select{ |c| ["ID Number"] }.each do |element|
                    case element['name']
                    when 'ID Number'
                        # 医師ID
                        identifier = FHIR::Identifier.new
                        identifier.system = "OID:1.2.392.100495.20.3.41.1#{@parser.get_sending_facility[:all]}"
                        identifier.value = element['value']
                        practitioner_role.identifier << identifier
                        # 役割
                        practitioner_role.code = [create_codeable_concept('doctor','Doctor','http://terminology.hl7.org/CodeSystem/practitioner-role')]
                        # 処方医の参照
                        get_resources_from_identifier('Practitioner', identifier).each do |entry|
                            practitioner_role.practitioner = create_reference(entry)
                        end
                    end
                end
            when 'Entering Organization'
                # ORC-17.入力組織（診療科）
                practitioner_role.specialty << generate_codeable_concept(field['array_data'].first)
            end
        end
        # 医療機関の参照
        get_resources_from_type('Organization').each do |entry|
            practitioner_role.organization = create_reference(entry)
        end
        entry = FHIR::Bundle::Entry.new
        entry.resource = practitioner_role
        [entry]
    end
end