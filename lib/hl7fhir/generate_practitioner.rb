# encoding: UTF-8
require_relative 'generate_abstract'

class GeneratePractitioner < GenerateAbstract
    def perform()
        practitioner = FHIR::Practitioner.new()
        practitioner.id = '0'

        orc_segment = @parser.get_parsed_segments('ORC')
        if orc_segment.nil? then
            return
        end
        
        orc_segment.first.select{|c| 
            Array[
                "Entered By",
                "Ordering Provider"
            ].include?(c['name'])
        }.each do |field|
            if ignore_fields?(field) then
                next
            end
            case field['name']
            when 'Entered By' then
                # ORC-10.入力者
                # 代行入力者として使用したいが、HL7v2では職種の判別ができない（医師 or 他職種）
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
                        practitioner.identifier.push(identifier)
                    end
                end
                field['array_data'].each do |record|
                    # 医師氏名
                    practitioner.name.push(generate_human_name(record))
                end

                # RXE-13.オーダ発行者の DEA 番号
                @parser.get_parsed_fields("RXE", "Ordering Provider's DEA Number").first['array_data'].each do |record|
                    identifier = FHIR::Identifier.new()
                    identifier.system = "OID:1.2.392.100495.20.3.32"
                    identifier.value = record[0]['value']
                    qualification = FHIR::Practitioner::Qualification.new()
                    qualification.identifier = identifier
                    practitioner.qualification = qualification
                end
            end
        end
        entry = FHIR::Bundle::Entry.new()
        entry.resource = practitioner
        return Array[entry]
    end
end