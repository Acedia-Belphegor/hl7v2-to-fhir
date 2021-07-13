require_relative 'generate_abstract'

class GenerateMedicationRequestInjection < GenerateAbstract
  def perform()
    results = []

    get_segment_groups.each do |segments|
      medication_request = FHIR::MedicationRequest.new
      medication_request.id = SecureRandom.uuid
      medication_request.status = :active
      medication_request.intent = :order
      dosage = FHIR::Dosage.new
      dosage.timing = FHIR::Timing.new
      medication_request.dosageInstruction << dosage
      dispense_request = FHIR::MedicationRequest::DispenseRequest.new
      medication_request.dispenseRequest = dispense_request
      medication = FHIR::Medication.new
      medication.id = medication_request.id
      medication.amount = FHIR::Ratio.new
      medication_request.contained << medication

      # ORCセグメント
      orc_segment = segments.find{|segment|segment[:segment_id] == 'ORC'}

      # ORC-2.依頼者オーダ番号
      medication_request.identifier << generate_identifier(orc_segment[:placer_order_number].first[:entity_identifier], 'urn:oid:1.2.392.100495.20.3.11')
      # ORC-4.依頼者グループ番号
      medication_request.identifier << generate_identifier(orc_segment[:placer_group_number].first[:entity_identifier], 'urn:oid:1.2.392.100495.20.3.81')
      # ORC-9.トランザクション日時(交付年月日)
      medication_request.authoredOn = Date.parse(orc_segment[:datetime_of_transaction].first[:time])
      # ORC-29.オーダタイプ
      medication_request.category << generate_codeable_concept(orc_segment[:order_type].first)

      # RXEセグメント
      rxe_segment = segments.find{|segment|segment[:segment_id] == 'RXE'}

      # RXE-2.与薬コード
      medication_request.category << generate_codeable_concept(rxe_segment[:give_code].first)

      # RXE-3.与薬量－最小 / RXE-5.与薬単位
      if rxe_segment[:give_amount_minimum].present?
        dose = FHIR::Dosage::DoseAndRate.new
        dose.doseQuantity = build_quantity(
          rxe_segment[:give_amount_minimum].to_f,
          rxe_segment[:give_units].first[:text],
          rxe_segment[:give_units].first[:identifier]
        )
        dosage.doseAndRate << dose
      end

      # RXE-7.依頼者の投薬指示
      if rxe_segment[:providers_administration_instructions].class == Array
        dosage.additionalInstruction.concat rxe_segment[:providers_administration_instructions].map{|e|generate_codeable_concept(e)}
      end

      # # RXE-15.処方箋番号
      # if rxe_segment[:prescription_number].present?
      #     medication_request.identifier << build_identifier(rxe_segment[:prescription_number], 'urn:oid:1.2.392.100495.20.3.11')
      # end

      # RXE-21.薬剤部門/治療部門による特別な調剤指示
      rxe_segment[:pharmacytreatment_suppliers_special_dispensing_instructions].each do |element|
        if element[:name_of_coding_system].in? %w[MR9P JHSI0001] # 処方区分
          medication_request.category << generate_codeable_concept(element)
        else
          dosage.additionalInstruction.concat << generate_codeable_concept(element)
        end
      end

      # RXE-23.与薬速度 / # RXE-24.与薬速度単位
      if rxe_segment[:give_rate_amount].present? && rxe_segment[:give_rate_units].present?
        if rxe_segment[:give_rate_units].first[:identifier].downcase == 'ml/hr'
          rate = FHIR::Dosage::DoseAndRate.new
          ratio = FHIR::Ratio.new
          ratio.numerator = build_quantity(rxe_segment[:give_rate_amount].to_f, 'ml')
          ratio.denominator = build_quantity(1, 'h')
          rate.rateRatio = ratio
          dosage.doseAndRate << rate
        end
      end

      # RXE-27.与薬指示
      if rxe_segment[:give_indication].present?
        dosage.timing.code = generate_codeable_concept(rxe_segment[:give_indication].first)
      end

      # TQ1セグメント
      tq1_segment = segments.find{|segment|segment[:segment_id] == 'TQ1'}

      # TQ1-3.繰返しパターン(あいまい指示)
      if tq1_segment[:repeat_pattern].present?
        dosage.timing.code = generate_codeable_concept(tq1_segment[:repeat_pattern].first[:repeat_pattern_code])
      end

      # TQ1-7.開始日時
      if tq1_segment[:start_date_time].present?
        timing_repeat = FHIR::Timing::Repeat.new
        period = FHIR::Period.new
        period.start = Date.parse(tq1_segment[:start_date_time].first[:time])
        # TQ1-8.終了日時
        if tq1_segment[:end_date_time].present?
          period.end = Date.parse(tq1_segment[:end_date_time].first[:time])
        end
        timing_repeat.boundsPeriod = period
        dosage.timing.repeat = timing_repeat
      end

      # TQ1-9.優先度
      if tq1_segment[:priority].present?
        priority = generate_codeable_concept(tq1_segment[:priority].first)
        if priority.coding.first.system == 'HL70485'
          medication_request.priority = 
            case priority.coding.first.code
            when 'S' then :stat # 緊急
            when 'A' then :asap # できるだけ早く
            when 'R' then :routine # ルーチン
            end
        end
      end

      # TQ1-11.テキスト指令
      dosage.patientInstruction = tq1_segment[:text_instruction]

      # RXRセグメント
      rxr_segment = segments.find{|segment|segment[:segment_id] == 'RXR'}

      # RXR-1.経路
      if rxr_segment[:route].present?
        dosage.route = generate_codeable_concept(rxr_segment[:route].first)
      end
        
      # RXR-2.部位
      if rxr_segment[:administration_site].present?
        dosage.site = generate_codeable_concept(rxr_segment[:administration_site].first)
      end
        
      # RXR-3.投薬装置
      if rxr_segment[:administration_device].present?
        extension = FHIR::Extension.new
        extension.url = "http://hl7fhir.jp/fhir/StructureDefinition/Extension-JPCore-AdministrationDevice"
        extension.valueCodeableConcept = generate_codeable_concept(rxr_segment[:administration_device].first)
        dosage.extension << extension
      end

      # RXR-4.投薬方法
      if rxr_segment[:administration_method].present?
        dosage.local_method = generate_codeable_concept(rxr_segment[:administration_method].first)
      end

      # RXR-5.経路指示
      if rxr_segment[:routing_instruction].present?
        # dosage.additionalInstruction << generate_codeable_concept(rxr_segment[:routing_instruction].first)

        extension = FHIR::Extension.new
        extension.url = "http://hl7fhir.jp/fhir/StructureDefinition/Extension-JPCore-RoutingInstruction"
        extension.valueCodeableConcept = generate_codeable_concept(rxr_segment[:routing_instruction].first)
        dosage.extension << extension
      end

      # RXR-6.投薬現場モディファイア
      if rxr_segment[:administration_site_modifier].present?
        dosage.additionalInstruction << generate_codeable_concept(rxr_segment[:administration_site_modifier].first)
      end

      # RXCセグメント
      segments.select{|segment|segment[:segment_id] == 'RXC'}.each do |rxc_segment|
        ingredient = FHIR::Medication::Ingredient.new

        # RXC-2.成分コード
        codeable_concept = generate_codeable_concept(rxc_segment[:component_code].first)
        if codeable_concept.coding.first.system == 'HOT'
          codeable_concept.coding.first.system = 'urn:oid:1.2.392.100495.20.2.74' # HOTコード
        end
        ingredient.itemCodeableConcept = codeable_concept

        # RXC-3.成分量 (TODO: R5になったら strengthQuantity に入れたい)
        extension = FHIR::Extension.new
        extension.url = "http://hl7fhir.jp/fhir/StructureDefinition/Extension-JPCore-ComponentAmount"
        extension.valueQuantity = build_quantity(
          rxc_segment[:component_amount].to_f,
          rxc_segment[:component_units].first[:text],
          rxc_segment[:component_units].first[:identifier]
        )
        ingredient.extension << extension

        # ratio = FHIR::Ratio.new
        # ratio.denominator = build_quantity(
        #     rxc_segment[:component_amount].to_f,
        #     rxc_segment[:component_units].first[:text],
        #     rxc_segment[:component_units].first[:identifier]
        # )
        # ingredient.strength = ratio
        medication.ingredient << ingredient
      end

      # Patientリソースの参照
      medication_request.subject = build_reference(get_resources_from_type('Patient').first)
      # PractitionerRoleリソースの参照
      medication_request.requester = build_reference(get_resources_from_type('PractitionerRole').first)
      # Coverageリソースの参照
      medication_request.insurance = get_resources_from_type('Coverage').map{|r|build_reference(r)}
      # Medicationリソースの参照
      medication_request.medicationReference = medication_request.contained.map{|resource|build_reference(resource)}&.first

      entry = FHIR::Bundle::Entry.new
      entry.resource = medication_request
      results << entry
    end

    results
  end

  private
  def get_segment_groups()
    result = []
    segments = []

    # ORC,RXE,TQ1,RXR,RXCを1つのグループにまとめて配列を生成する
    get_message.select{|segment|segment[:segment_id].in? %w[ORC RXE TQ1 RXR RXC]}.each do |segment|
      # ORCの出現を契機に配列を作成する
      if segment[:segment_id] == 'ORC'
        result << segments if segments.present?
        segments = []
      end
      segments << segment
    end
    result << segments if segments.present?
    result
  end
end
__END__

注射薬剤の混注表現
http://hl7.org/fhir/medicationrequest0322.json.html
