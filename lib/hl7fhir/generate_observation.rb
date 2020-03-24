# encoding: UTF-8
require_relative 'generate_abstract'

class GenerateObservation < GenerateAbstract
    def perform()
        results = []        
        get_segments_group.each do |segments|
            segments.each do |segment|                
                case segment[0]['value']
                when 'ORC'
                    segment.select{ |c| ["Placer Order Number"].include?(c['name']) }.each do |field|
                        next if ignore_fields?(field)
                        case field['name']
                        when 'Placer Order Number'
                            # ORC-2.依頼者オーダ番号
                            @identifier = FHIR::Identifier.new
                            @identifier.system = 'ORC-2'
                            @identifier.value = field['value']
                        end
                    end
                when 'SPM'
                    @specimen_ids = []
                    segment.select{ |c| ["Set ID – SPM","Specimen ID "].include?(c['name']) }.each do |field|
                        next if ignore_fields?(field)
                        case field['name']
                        when 'Set ID – SPM'
                            # SPM-1.セットID-SPM
                            identifier = FHIR::Identifier.new
                            identifier.system = 'SPM-1'
                            identifier.value = field['value']
                            @specimen_ids << identifier
                        when 'Specimen ID '
                            # SPM-2.検体ID
                            identifier = FHIR::Identifier.new
                            identifier.system = 'SPM-2'
                            identifier.value = field['value']
                            @specimen_ids << identifier
                        end
                    end
                when 'OBX'
                    observation = FHIR::Observation.new
                    observation.id = SecureRandom.uuid
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
                                when 'F' then :final
                                when 'C' then :amended
                                when 'D' then :cancelled
                                when 'P' then :preliminary
                                end
                        when "Date/Time of the Observation"
                            # OBX-14.検査日時
                            observation.effectiveDateTime = DateTime.parse(field['value'])
                        end
                    end
                    observation.identifier << @identifier
                    # 検体の参照
                    get_resources_from_identifier('Specimen', @specimen_ids).each do |entry|
                        observation.specimen = create_reference(entry)
                    end
                    # 患者の参照
                    get_resources_from_type('Patient').each do |entry|
                        observation.subject = create_reference(entry)
                    end
                    entry = FHIR::Bundle::Entry.new
                    entry.resource = observation
                    results << entry
                end
            end
        end
        results
    end

    def get_segments_group()
        segments_group = []
        segments = []

        message_type = @parser.get_parsed_fields('MSH','Message Type').first
        segment_ids = 
            case message_type['array_data'].first.select{|c| c['name'] == 'Message Structure'}.first['value']
            when 'OUL_R22' then ['SPM','ORC','OBR','OBX']
            when 'ORU_R01' then ['ORC','OBR','OBX']
            else ['OBX']
            end

        # SPM,ORC,OBR,OBXを1つのグループにまとめて配列を生成する
        @parser.get_parsed_message().select{ |c| segment_ids.include?(c[0]['value']) }.each do |segment|
            if segment[0]['value'] == segment_ids.first
                segments_group << segments if !segments.empty?
                segments = []
            end
            segments << segment
        end
        segments_group << segments if !segments.empty?
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