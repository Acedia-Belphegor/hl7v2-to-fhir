# encoding: UTF-8
require_relative 'generate_abstract'

class GenerateAllergyIntolerance < GenerateAbstract
    def perform()
        result = Array[]
        @parser.get_parsed_segments('AL1').each do |segment|
            allergy_intolerance = FHIR::AllergyIntolerance.new()
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
                    type_code = get_codeable_concept(field['array_data'].first)
                    allergy_intolerance.category = 
                        case type_code.coding.code
                        when 'DA' then 'medication' # Drug Allergy 薬剤アレルギー
                        when 'FA' then 'food' # Food Allergy 食物アレルギー
                        when 'EA' then 'environment' # Environmental Allergy 環境アレルギー
                        end
                when 'Allergen Code/Mnemonic/Description' then
                    # AL1-3.アレルゲン情報
                    allergy_intolerance.code = get_codeable_concept(field['array_data'].first)
                when 'Allergy Severity Code' then
                    # AL1-4.アレルギー重症度
                    severity_code = get_codeable_concept(field['array_data'].first)
                    allergy_intolerance.criticality = 
                        case severity_code.coding.code
                        when 'SV' then 'high' # Severe 重度
                        # when 'MO' then '' # Moderate 中程度
                        when 'MI' then 'low' # Mild 軽度
                        end
                when 'Allergy Reaction Code' then
                    # AL1-5.アレルギー反応情報
                    # reaction.manifestation
                when 'Identification Date' then
                    # AL1-6.判定日
                    # reaction.onset
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