require_relative 'generate_abstract'

class GenerateSpecimenObservation < GenerateAbstract
  def perform()
    results = []

    get_segment_groups.each do |segments|
      specimen = FHIR::Specimen.new
      specimen.id = SecureRandom.uuid

      # SPM
      spm_segment = get_segments('SPM')&.first
      if spm_segment.present?
        # SPM-4.検体タイプ
        specimen.type = generate_codeable_concept(spm_segment[:specimen_type].first)

        # SPM-17.検体採取日時
        if spm_segment[:specimen_collection_date_time].present?
          collection = FHIR::Specimen::Collection.new
          collection.collectedDateTime = spm_segment[:specimen_collection_date_time].first[:range_start_date_time][:time]
          specimen.collection = collection
        end
      end

      # OBR
      obr_segment = get_segments('OBR')&.first
      if obr_segment.present?
        # OBR-4.検査項目ID
        processing = FHIR::Specimen::Processing.new
        processing.procedure = generate_codeable_concept(obr_segment[:universal_service_identifier].first)
        specimen.processing = processing

        # OBR-7.検査/採取日時
        if obr_segment[:observation_date_time_].present? && specimen.collection.blank?
          collection = FHIR::Specimen::Collection.new
          collection.collectedDateTime = obr_segment[:observation_date_time_].first[:time]
          specimen.collection = collection
        end
      end
        
      # OBX
      segments.select{|segment|segment[:segment_id] == 'OBX'}.each do |obx_segment|
        observation = FHIR::Observation.new
        observation.id = SecureRandom.uuid
        observation.category = build_codeable_concept('laboratory','検体検査','http://hl7.org/fhir/ValueSet/observation-category')                    

        # OBX-3.検査項目ID
        observation.code = generate_codeable_concept(obx_segment[:observation_identifier].first)

        # OBX-5.検査値 / # OBX-6.単位
        case obx_segment[:value_type]
        when 'NM' # Numeric
          observation.valueQuantity = build_quantity(
            obx_segment[:observation_value].to_f,
            obx_segment[:units].first[:text],
            obx_segment[:units].first[:identifier]
          )
        when 'CWE' # Coded With Exceptions
          observation.valueCodeableConcept = generate_codeable_concept(obx_segment[:observation_value].first)
        else
          observation.valueString = obx_segment[:observation_value]
        end

        # OBX-7.基準値範囲
        reference_range = FHIR::Observation::ReferenceRange.new
        reference_range.text = obx_segment[:references_range]
        # 値がハイフンで区切られている場合は範囲値とみなして分割する
        if reference_range.text.match(/^.+-.+$/)
          reference_range.text.split('-').each do |value|
            quantity = FHIR::Quantity.new
            quantity.value = value
            quantity.unit = observation.valueQuantity.unit if observation.valueQuantity.present?
            reference_range.low.blank? ? reference_range.low = quantity : reference_range.high = quantity
          end
        end
        observation.referenceRange = reference_range

        # OBX-8.異常フラグ
        if obx_segment[:abnormal_flags].present?
          observation.interpretation << conversion_interpretation(obx_segment[:abnormal_flags])
        end

        # OBX-11.検査結果状態
        observation.status = case obx_segment[:observation_result_status]
                             when 'F' then :final # 最終結果
                             when 'C' then :amended # 到着レコードは修正であり結果を書き換え
                             when 'D' then :cancelled # レコードを削除する
                             when 'P' then :preliminary # 事前結果
                             end

        # OBX-14.検査日時
        if obx_segment[:date_time_of_the_observation].present?
          observation.effectiveDateTime = DateTime.parse(obx_segment[:date_time_of_the_observation].first[:time])
        end

        specimen.contained << observation
      end

      entry = FHIR::Bundle::Entry.new
      entry.resource = specimen
      results << entry
    end

    results
  end

  private
  def get_segment_groups()
    result = []
    segments = []

    # MSH-9.MessageTypeの値に応じて、読込対象とするセグメントを識別する
    segment_ids = case get_segments('MSH').first[:message_type].first[:message_structure]
                  when 'OUL_R22' then %w[SPM ORC OBR OBX]
                  when 'ORU_R01' then %w[ORC OBR OBX]
                  end

    # SPM,ORC,OBR,OBXを1つのグループにまとめて配列を生成する
    get_message.select{|segment|segment[:segment_id].in? segment_ids}.each do |segment|
      if segment[:segment_id] == segment_ids.first
        result << segments if segments.present?
        segments = []
      end
      segments << segment
    end
    result << segments if segments.present?
    result
  end

  def conversion_interpretation(value)
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