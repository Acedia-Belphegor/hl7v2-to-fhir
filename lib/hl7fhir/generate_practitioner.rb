# encoding: UTF-8
require_relative 'generate_abstract'

class GeneratePractitioner < GenerateAbstract
    def perform()
        practitioner = FHIR::Practitioner.new()

        orc_segment = @parser.get_parsed_segments('ORC')
        if orc_segment.nil? then
            return
        end
        
        orc_segment.first.select{|c| 
            Array[
                "Ordering Provider"
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
                        practitioner.identifier = identifier
                    end
                end
                field['array_data'].each do |record|
                    # 医師氏名
                    practitioner.name.push(get_human_name(record))
                end
            end
        end
        entry = FHIR::Bundle::Entry.new()
        entry.resource = practitioner
        return Array[entry]
    end
end