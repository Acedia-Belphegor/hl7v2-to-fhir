# encoding: UTF-8
require_relative 'generate_abstract'

class GenerateSpecimenContained < GenerateAbstract
    def perform()
        results = []        
        get_segments_group.each do |segments|
            specimen = FHIR::Specimen.new
            specimen.id = results.length
            segments.each do |segment|
                case segment[0]['value']
                when 'SPM'
                    segment.select{|c| 
                        [
                            "Set ID – SPM",
                            "Specimen ID ",
                            "Specimen Type",
                            "Specimen Collection Date/Time",
                        ].include?(c['name'])
                    }.each do |field|
                        next if ignore_fields?(field)
                        case field['name']
                        when 'Set ID – SPM'
                            # SPM-1.セットID-SPM
                            identifier = FHIR::Identifier.new
                            identifier.system = 'SPM-1'
                            identifier.value = field['value']
                            specimen.identifier << identifier
                        when 'Specimen ID '
                            # SPM-2.検体ID
                            identifier = FHIR::Identifier.new
                            identifier.system = 'SPM-2'
                            identifier.value = field['value']
                            specimen.identifier << identifier
                        when 'Specimen Type'
                            # SPM-4.検体タイプ
                            specimen.type = generate_codeable_concept(field['array_data'].first)
                        when 'Specimen Collection Date/Time'
                            # SPM-17.検体採取日時
                            date_time = parse_str_datetime(field['value'])
                            if date_time.present?
                                collection = FHIR::Specimen::Collection.new
                                collection.collectedDateTime = date_time
                                specimen.collection = collection
                            end
                        end
                    end
                when 'OBR'
                    segment.select{|c| 
                        [
                            "Universal Service Identifier",
                            "Observation Date/Time #",
                        ].include?(c['name'])
                    }.each do |field|
                        next if ignore_fields?(field)
                        case field['name']
                        when 'Universal Service Identifier'
                            # OBR-4.検査項目ID
                            processing = FHIR::Specimen::Processing.new
                            processing.procedure = generate_codeable_concept(field['array_data'].first)
                            specimen.processing = processing
                        when 'Observation Date/Time #'
                            # OBR-7.検査/採取日時
                            date_time = parse_str_datetime(field['value'])
                            if date_time.present?
                                collection = FHIR::Specimen::Collection.new
                                collection.collectedDateTime = date_time
                                specimen.collection = collection
                            end
                        end
                    end
                when 'OBX'
                    observation = FHIR::Observation.new
                    observation.id = specimen.contained.length
                    observation.category = create_codeable_concept('laboratory','検体検査','http://hl7.org/fhir/ValueSet/observation-category')                    
                    segment.select{|c| 
                        [
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
                        next if ignore_fields?(field)
                        case field['name']
                        when "Value Type"
                            # OBX-2.値型
                            @value_type = field['value']
                        when "Observation Identifier"
                            # OBX-3.検査項目ID
                            observation.code = generate_codeable_concept(field['array_data'].first)
                        when "Observation Value"
                            # OBX-5.検査値
                            case @value_type
                            when 'NM' # Numeric                                
                                quantity = FHIR::Quantity.new
                                quantity.value = field['value']
                                observation.valueQuantity = quantity
                            when 'ST' # String Data                                
                                observation.valueString = field['value']
                            when 'CWE' # Coded With Exceptions                                
                                observation.valueCodeableConcept = generate_codeable_concept(field['array_data'].first)
                            else
                                observation.valueString = field['value']
                            end
                        when "Units"
                            # OBX-6.単位
                            if observation.valueQuantity.present?
                                units = generate_codeable_concept(field['array_data'].first)
                                quantity = observation.valueQuantity
                                quantity.unit = units.coding.display 
                            end
                        when "References Range"
                            # OBX-7.基準値範囲
                            reference_range = FHIR::Observation::ReferenceRange.new
                            reference_range.text = field['value']
                            # 値がハイフンで区切られている場合は範囲値とみなして分割する
                            if reference_range.text.match(/^.+-.+$/)
                                reference_range.text.split('-').each do |value|
                                    quantity = FHIR::Quantity.new
                                    quantity.value = value
                                    quantity.unit = observation.valueQuantity.unit if !observation.valueQuantity.nil?
                                    reference_range.low.nil? ? reference_range.low = quantity : reference_range.high = quantity
                                end
                            end
                            observation.referenceRange = reference_range
                        when "Abnormal Flags"
                            # OBX-8.異常フラグ
                            observation.interpretation << get_interpretation(field['value']) if field['value'].present?
                        when "Observation Result Status"
                            # OBX-11.検査結果状態
                            observation.status = 
                                case field['value']
                                when 'F' then 'final'
                                when 'C' then 'amended'
                                when 'D' then 'cancelled'
                                when 'P' then 'preliminary'
                                end
                        when "Date/Time of the Observation"
                            # OBX-14.検査日時
                            observation.effectiveDateTime = DateTime.parse(field['value'])
                        end
                    end
                    specimen.contained << observation
                end
            end
            # 患者の参照
            get_resources_from_type('Patient').each do |entry|
                specimen.subject = create_reference(entry)
            end
            entry = FHIR::Bundle::Entry.new
            entry.resource = specimen
            results << entry
        end
        results
    end

    def get_segments_group()
        segments_group = []
        segments = []

        # MSH-9.MessageTypeの値に応じて、読込対象とするセグメントを識別する
        message_type = @parser.get_parsed_fields('MSH','Message Type').first
        segment_ids = 
            case message_type['array_data'].first.select{ |c| c['name'] == 'Message Structure' }.first['value']
            when 'OUL_R22' then ['SPM','ORC','OBR','OBX']
            when 'ORU_R01' then ['ORC','OBR','OBX']
            end

        # SPM,ORC,OBR,OBXを1つのグループにまとめて配列を生成する
        @parser.get_parsed_message.select{ |c| segment_ids.include?(c[0]['value']) }.each do |segment|
            if segment[0]['value'] == segment_ids.first
                segments_group << segments if segments.present?
                segments = []
            end
            segments << segment
        end
        segments_group << segments if segments.present?
        segments_group
    end

    def get_interpretation(value)
        codeable_concept = FHIR::CodeableConcept.new
        coding = FHIR::Coding.new
        coding.code = 
            case value
            when 'MS','VS' then 'S' # MS:Moderately sensitive 少し敏感 / VS:Very sensitive 過敏
            else value
            end
        coding.display = 
            case coding.code
            when 'L' then 'Low' # Below low normal 基準値下限以下
            when 'H' then 'High' # Above high normal 基準値上限以上
            when 'LL' then 'Critical Low' # Below lower panic limits パニック下限以下
            when 'HH' then 'Critical High' # Above upper panic limits パニック上限以上
            when '<' then 'Off scale low' # Below absolute low-off instrument scale 測定限界下限未満
            when '>' then 'Off scale high' # Above absolute high-off instrument scale 測定限界上限越
            when 'N' then 'Normal' # Normal (applies to non-numeric results) 正常(非数値結果に適用)
            when 'A' then 'Abnormal' # Abnormal (applies to non-numeric results) 異常(非数値結果に適用)
            when 'AA' then 'Critical abnormal' # Very abnormal (applies to non-numeric units, analagous to panic limits for numeric units) 非常に異常
            when 'U' then 'Significant change up' # Significant change up 大幅な上昇変化
            when 'D' then 'Significant change down' # Significant change down 大幅な下降変化
            when 'B' then 'Better' # Better--use when direction not relevant 改善
            when 'W' then 'Worse' # Worse--use when direction not relevant 悪化
            when 'S' then 'Susceptible' # Sensitive 敏感
            when 'R' then 'Resistant' # Resistant 耐性
            when 'I' then 'Intermediate' # Intermediate 中間
            end
        coding.system = 'http://terminology.hl7.org/CodeSystem/v3-ObservationInterpretation'
        codeable_concept.coding = coding
        codeable_concept
    end
end