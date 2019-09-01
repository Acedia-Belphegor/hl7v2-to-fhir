# encoding: UTF-8
require_relative 'generate_abstract'

class GenerateAllergyIntolerance < GenerateAbstract
    def perform()
        result = Array[]
        
        # AL1セグメント
        @parser.get_parsed_segments('AL1').each do |segment|
            allergy_intolerance = FHIR::AllergyIntolerance.new()
            allergy_intolerance.id = result.length
            reaction = FHIR::AllergyIntolerance::Reaction.new()
            segment.select{|c| 
                Array[
                    "Allergen Type Code",
                    "Allergen Code/Mnemonic/Description",
                    "Allergy Severity Code",
                    "Allergy Reaction Code",
                    "Identification Date",
                ].include?(c['name'])
            }.each do |field|
                if ignore_fields?(field) then
                    next
                end
                case field['name']
                when 'Allergen Type Code' then
                    # AL1-2.アレルゲン分類
                    allergy_intolerance.category = 
                        case generate_codeable_concept(field['array_data'].first).coding.code
                        when 'DA' then 'medication' # Drug Allergy 薬剤アレルギー
                        when 'FA' then 'food' # Food Allergy 食物アレルギー
                        when 'EA' then 'environment' # Environmental Allergy 環境アレルギー
                        end
                when 'Allergen Code/Mnemonic/Description' then
                    # AL1-3.アレルゲン情報
                    allergy_intolerance.code = generate_codeable_concept(field['array_data'].first)
                when 'Allergy Severity Code' then
                    # AL1-4.アレルギー重症度
                    severity_code = generate_codeable_concept(field['array_data'].first)
                    allergy_intolerance.criticality = 
                        case severity_code.coding.code
                        when 'SV' then 'high' # Severe 重度
                        when 'MI' then 'low' # Mild 軽度
                        when 'MO' then '' # Moderate 中等度
                        end
                when 'Allergy Reaction Code' then
                    # AL1-5.アレルギー反応情報
                when 'Identification Date' then
                    # AL1-6.判定日
                end
            end
            allergy_intolerance.reaction = reaction
            entry = FHIR::Bundle::Entry.new()
            entry.resource = allergy_intolerance
            result.push(entry)
        end

        # IAMセグメント
        @parser.get_parsed_segments('IAM').each do |segment|
            allergy_intolerance = FHIR::AllergyIntolerance.new()
            reaction = FHIR::AllergyIntolerance::Reaction.new()
            segment.select{|c| 
                Array[
                    "Allergen Type Code",
                    "Allergen Code/Mnemonic/Description",
                    "Allergy Severity Code",
                    "Allergy Reaction Code",
                    "Allergy Unique Identifier",
                    "Sensitivity to Causative Agent Code",
                    "Onset Date",
                    "Onset Date Text",
                    "Reported Date/Time",
                    "Reported By",
                    "Statused by Person",
                ].include?(c['name'])
            }.each do |field|
                if ignore_fields?(field) then
                    next
                end
                case field['name']
                when 'Allergen Type Code' then
                    # IAM-2.アレルゲン分類
                    allergy_intolerance.category = 
                        case generate_codeable_concept(field['array_data'].first).coding.code
                        when 'DA' then 'medication' # Drug Allergy 薬剤アレルギー
                        when 'FA' then 'food' # Food Allergy 食物アレルギー
                        when 'EA' then 'environment' # Environmental Allergy 環境アレルギー
                        end
                when 'Allergen Code/Mnemonic/Description' then
                    # IAM-3.アレルゲン情報
                    allergy_intolerance.code = generate_codeable_concept(field['array_data'].first)
                when 'Allergy Severity Code' then
                    # IAM-4.アレルギー重症度
                    allergy_intolerance.criticality = 
                        case generate_codeable_concept(field['array_data'].first).coding.code
                        when 'SV' then 'high' # Severe 重度
                        when 'MI' then 'low' # Mild 軽度
                        when 'MO' then '' # Moderate 中等度
                        end
                when 'Allergy Reaction Code' then
                    # IAM-5.アレルギー反応情報
                    reaction.description = field['value']
                when 'Allergy Unique Identifier' then
                    # IAM-7.アレルギー識別情報
                    identifier = FHIR::Identifier.new()
                    identifier.system = "IAM-7"
                    identifier.value = field['value']
                    allergy_intolerance.identifier.push(identifier)
                when 'Sensitivity to Causative Agent Code' then
                    # IAM-9.アレルギー物質に対する感受性
                    allergy_intolerance.type = 
                        case generate_codeable_concept(field['array_data'].first).coding.code
                        when 'AL' then 'allergy' # Allergy アレルギー
                        when 'IN' then 'intolerance' # Intolerance 過敏症
                        when 'CT' then '' # Contraindication 禁忌
                        when 'AD' then '' # Adverse Reaction (Not otherwise classified) 他に分類できない副作用
                        end
                when 'Onset Date' then
                    # IAM-11.アレルギー発症日
                    allergy_intolerance.onsetDateTime = parse_str_datetime(field['value'])
                when 'Onset Date Text' then
                    # IAM-12.アレルギー発症時期
                    allergy_intolerance.onsetString = field['value']
                when 'Reported Date/Time' then
                    # IAM-13.情報提供日時
                    allergy_intolerance.recordedDate = parse_str_datetime(field['value'])
                when '' then
                    # IAM-14.情報提供者
                when '' then
                    # IAM-18.確認者
                end
            end
            allergy_intolerance.reaction = reaction
            entry = FHIR::Bundle::Entry.new()
            entry.resource = allergy_intolerance
            result.push(entry)
        end
        return result
    end
end