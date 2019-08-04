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
                # 依頼者
                field['array_data'].first.select{|c|
                    Array[
                        "ID Number",
                    ]
                }.each do |element|
                    case element['name']
                    when 'ID Number' then
                        # 医師ID
                        identifier = FHIR::Identifier.new()
                        identifier.system = "OID:1.2.392.100495.20.3.41#{get_facility_id}"
                        identifier.value = element['value']
                        practitioner_role.identifier = identifier
                    end
                end
            when 'Entering Organization' then
                # 入力組織
                practitioner_role.specialty.push(get_codeable_concept(field['array_data'].first))
            end
        end
        entry = FHIR::Bundle::Entry.new()
        entry.resource = practitioner_role
        return Array[entry]
    end
end