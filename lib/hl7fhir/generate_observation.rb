# encoding: UTF-8
require_relative 'generate_abstract'

class GenerateObservation < GenerateAbstract
    def perform()
        # SPM,ORC,OBR,OBX を1つのグループにする
        segments_group = Array[]
        segments = Array[]
        result = Array[]
        @parser.get_parsed_message().select{|c| 
            Array['SPM','ORC','OBR','OBX'].include?(c[0]['value'])
        }.each do |segment|
            if segment[0]['value'] == 'SPM' then
                segments_group.push(segments) if !segments.empty?
                segments = Array[]
            end
            segments.push(segment)
        end
        segments_group.push(segments) if !segments.empty?
        
        segments_group.each do |segments|
            observation = FHIR::Observation.new()
            segments.each do |segment|
                specimen_ids = []
                case segment[0]['value']
                when 'SPM' then
                    segment.select{|c| 
                        Array[
                            "Set ID – SPM",
                            "Specimen ID ",
                        ].include?(c['name'])
                    }.each do |field|
                        if ignore_fields?(field) then
                            next
                        end
                        case field['name']
                        when 'Set ID – SPM' then
                            # SPM-1.セットID-SPM
                            identifier = FHIR::Identifier.new()
                            identifier.system = 'SPM-1'
                            identifier.value = field['value']
                            specimen_ids.push(identifier)
                        when 'Specimen ID ' then
                            # SPM-2.検体ID
                            identifier = FHIR::Identifier.new()
                            identifier.system = 'SPM-2'
                            identifier.value = field['value']
                            specimen_ids.push(identifier)
                        end                        
                    end
                    get_resources_from_identifier('Specimen', specimen_ids).each do |specimen|
                        reference = FHIR::Reference.new()
                        reference.type = specimen.resource.resourceType
                        reference.identifier = specimen.resource.identifier
                        observation.specimen = reference
                    end
                when 'OBX' then
                    segment.select{|c| 
                        Array[
                            "Value Type",
                            "Observation Identifier",
                            "Observation Value",
                            "Units",
                            "References Range",
                            "Abnormal Flags",
                            "Observation Result Status",
                            "Date/Time of the Observation",
                        ].include?(c['name'])
                    }.each do |field|
                        if ignore_fields?(field) then
                            next
                        end
                        case field['name']
                        when "Value Type" then
                            # OBX-2.値型
                            @value_type = field['value']
                        when "Observation Identifier" then
                            # OBX-3.検査項目ID
                            observation.code = get_codeable_concept(field['array_data'].first)
                        when "Observation Value" then
                            # OBX-5.検査値
                            case @value_type
                            when 'NM' then
                                quantity = FHIR::Quantity.new()
                                quantity.value = field['value']
                                observation.valueQuantity = quantity
                            when 'ST' then
                                observation.valueString = field['value']
                            when 'CWE' then
                                observation.valueCodeableConcept = get_codeable_concept(field['array_data'].first)
                            end
                        when "Units" then
                            # OBX-6.単位
                            if !observation.valueQuantity.nil? then
                                units = get_codeable_concept(field['array_data'].first)
                                quantity = observation.valueQuantity
                                quantity.unit = units.coding.display 
                            end
                        when "References Range" then
                            # OBX-7.基準値範囲
                            reference_range = FHIR::Observation::ReferenceRange.new()
                            reference_range.text = field['value']
                            # 値がハイフンで区切られている場合は範囲値とみなして分割する
                            if reference_range.text.match(/^.-.+$/) then
                                reference_range.text.split('-').each do |value|
                                    quantity = FHIR::Quantity.new()
                                    quantity.value = value
                                    quantity.unit = observation.valueQuantity.unit if !observation.valueQuantity.nil?
                                    if reference_range.low.nil? then
                                        reference_range.low = quantity # 下限値
                                    else
                                        reference_range.high = quantity # 上限値
                                    end
                                end
                            end
                            observation.referenceRange = reference_range
                        when "Abnormal Flags" then
                            # OBX-8.異常フラグ
                            field['array_data'].each do |record|
                                observation.interpretation.push(get_codeable_concept(record))
                            end                    
                        when "Observation Result Status" then
                            # OBX-11.検査結果状態
                            observation.status = 
                                case field['value']
                                when 'F' then 'final'
                                when 'C' then 'amended'
                                when 'D' then 'cancelled'
                                when 'P' then 'preliminary'
                                end
                        when "Date/Time of the Observation" then
                            # OBX-14.検査日時
                            observation.effectiveDateTime = DateTime.parse(field['value'])
                        end
                    end
                end
            end
            # 患者
            patient = get_resources_from_type('Patient')
            if !patient.empty? then
                reference = FHIR::Reference.new()
                reference.type = patient.first.resource.resourceType
                reference.identifier = patient.first.resource.identifier
                observation.subject = reference
            end
            entry = FHIR::Bundle::Entry.new()
            entry.resource = observation
            result.push(entry)        
        end
        return result
    end
end