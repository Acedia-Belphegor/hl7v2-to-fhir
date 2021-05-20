require_relative 'generate_abstract'

class GenerateAllergyIntolerance < GenerateAbstract
  def perform()
    [ create_al1, create_iam ].compact.reject(&:empty?).flatten
  end

  def create_al1()
    results = []

    get_segments('AL1').each do |al1_segment|
      allergy_intolerance = FHIR::AllergyIntolerance.new
      allergy_intolerance.id = SecureRandom.uuid
      allergy_intolerance.type = :allergy
      reaction = FHIR::AllergyIntolerance::Reaction.new
      allergy_intolerance.reaction << reaction

      # AL1-2.アレルゲン分類
      if al1_segment[:allergen_type_code].present?
        allergy_intolerance.category << 
          case al1_segment[:allergen_type_code].first[:identifier]
          when 'DA' then :medication # Drug Allergy 薬剤アレルギー
          when 'FA' then :food # Food Allergy 食物アレルギー
          when 'EA' then :environment # Environmental Allergy 環境アレルギー
          else al1_segment[:allergen_type_code].first[:identifier]
          end
      end

      # AL1-3.アレルゲン情報
      allergy_intolerance.code = generate_codeable_concept(al1_segment[:allergen_code_mnemonic_description].first)

      # AL1-4.アレルギー重症度
      if al1_segment[:allergy_severity_code].present?
        reaction.severity = 
          case al1_segment[:allergy_severity_code].first[:identifier]
          when 'SV' then :severe # Severe 重度
          when 'MI' then :mild # Mild 軽度
          when 'MO' then :moderate # Moderate 中等度
          end
      end

      # AL1-5.アレルギー反応情報
      if al1_segment[:allergy_reaction_code].present?
        codeable_concept = FHIR::CodeableConcept.new
        codeable_concept.text = al1_segment[:allergy_reaction_code]
        reaction.manifestation << codeable_concept
      end

      # AL1-6.判定日
      if al1_segment[:identification_date].present?
        allergy_intolerance.onsetDateTime = Date.parse(al1_segment[:identification_date])
      end

      # Patientリソースの参照
      allergy_intolerance.patient = create_reference(get_resources_from_type('Patient').first)

      entry = FHIR::Bundle::Entry.new
      entry.resource = allergy_intolerance
      results << entry
    end

    results
  end

  def create_iam()
    results = []

    get_segments('IAM').each do |iam_segment|
      allergy_intolerance = FHIR::AllergyIntolerance.new
      allergy_intolerance.id = SecureRandom.uuid
      reaction = FHIR::AllergyIntolerance::Reaction.new
      allergy_intolerance.reaction << reaction

      # IAM-2.アレルゲン分類
      if iam_segment[:allergen_type_code].present?
        allergy_intolerance.category << 
          case iam_segment[:allergen_type_code].first[:identifier]
          when 'DA' then :medication # Drug Allergy 薬剤アレルギー
          when 'FA' then :food # Food Allergy 食物アレルギー
          when 'EA' then :environment # Environmental Allergy 環境アレルギー
          else iam_segment[:allergen_type_code].first[:identifier]
          end
      end

      # IAM-3.アレルゲン情報
      allergy_intolerance.code = generate_codeable_concept(iam_segment[:allergen_code_mnemonic_description].first)

      # IAM-4.アレルギー重症度
      if iam_segment[:allergy_severity_code].present?
        reaction.severity = 
          case iam_segment[:allergy_severity_code].first[:identifier]
          when 'SV' then :severe # Severe 重度
          when 'MI' then :mild # Mild 軽度
          when 'MO' then :moderate # Moderate 中等度
          end
      end

      # IAM-5.アレルギー反応情報
      if iam_segment[:allergy_reaction_code].present?
        codeable_concept = FHIR::CodeableConcept.new
        codeable_concept.text = iam_segment[:allergy_reaction_code]
        reaction.manifestation << codeable_concept
      end

      # IAM-7.アレルギー識別情報
      if iam_segment[:allergy_unique_identifier].present?
        allergy_intolerance.identifier << create_identifier(iam_segment[:allergy_unique_identifier].first[:entity_identifier], nil)
      end

      # IAM-9.アレルギー物質に対する感受性
      if iam_segment[:sensitivity_to_causative_agent_code].present?
        allergy_intolerance.type = 
          case iam_segment[:sensitivity_to_causative_agent_code].first[:identifier]
          when 'AL' then :allergy # Allergy アレルギー
          when 'IN' then :intolerance # Intolerance 過敏症
          when 'CT' then :contraindication # Contraindication 禁忌
          when 'AD' then :adverse # Adverse Reaction (Not otherwise classified) 他に分類できない副作用
          end
      end

      # IAM-11.アレルギー発症日
      if iam_segment[:onset_date].present?
        if iam_segment[:onset_date].length == 8
          allergy_intolerance.onsetDateTime = Date.parse(iam_segment[:onset_date])
        else
          allergy_intolerance.onsetString = iam_segment[:onset_date]
        end
      end

      # IAM-12.アレルギー発症時期
      if iam_segment[:onset_date_text].present?
        allergy_intolerance.onsetString = iam_segment[:onset_date_text]
      end

      # IAM-13.情報提供日時

      # IAM-14.情報提供者

      # IAM-15.情報提供者と患者の関係

      # IAM-16.要注意物品コード
      if iam_segment[:alert_device_code].present?
        reaction.substance = generate_codeable_concept(iam_segment[:alert_device_code].first)
      end

      # IAM-17.アレルギー臨床確認状況
      if iam_segment[:allergy_clinical_status_code].present?
        hash = case iam_segment[:allergy_clinical_status_code].first[:identifier]
               when 'U' # 未確認
                 { verification_code: "unconfirmed", verification_display: "Unconfirmed" }
               when 'C' # 確認済
                 { verification_code: "confirmed", verification_display: "Confirmed", clinical_code: "active", clinical_display: "Active" }
               when 'I' # 確認済(非活性)
                 { verification_code: "confirmed", verification_display: "Confirmed", clinical_code: "inactive", clinical_display: "Inactive" } 
               when 'E' # 誤り
                 { verification_code: "entered-in-error", verification_display: "Entered in Error" }
               end

        if hash.present?
          allergy_intolerance.verificationStatus = create_codeable_concept(
            hash[:verification_code], 
            hash[:verification_display], 
            "http://hl7.org/fhir/ValueSet/allergyintolerance-verification"
          )
          if hash[:clinical_code].present?
            allergy_intolerance.clinicalStatus = create_codeable_concept(
              hash[:clinical_code],
              hash[:clinical_display],
              "http://hl7.org/fhir/ValueSet/allergyintolerance-clinical"
            )
          end
        end
      end

      # Patientリソースの参照
      allergy_intolerance.patient = create_reference(get_resources_from_type('Patient').first)

      entry = FHIR::Bundle::Entry.new
      entry.resource = allergy_intolerance
      results << entry
    end

    results
  end    
end