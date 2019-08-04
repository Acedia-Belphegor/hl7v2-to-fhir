# encoding: UTF-8
require_relative 'generate_abstract'

class GenerateMedicationRequest < GenerateAbstract
    def perform()
        # ORC,RXE,TQ1,RXR を1つのグループにする
        segments_group = Array[]
        segments = Array[]
        result = Array[]
        @parser.get_parsed_message().select{|c| 
            Array['ORC','RXE','TQ1','RXR'].include?(c[0]['value'])
        }.each do |segment|
            if segment[0]['value'] == 'ORC' then
                segments_group.push(segments) if !segments.empty?
                segments = Array[]
            end
            segments.push(segment)
        end
        segments_group.push(segments) if !segments.empty?

        segments_group.each do |segments|
            medication_request = FHIR::MedicationRequest.new()
            dosage = FHIR::Dosage.new()
            segments.each do |segment|
                case segment[0]['value']
                when 'ORC' then
                    segment.select{|c| 
                        Array[
                            "Placer Order Number",
                            "Placer Group Number",
                            "Date/Time of Transaction",
                        ].include?(c['name'])
                    }.each do |field|
                        if ignore_fields?(field) then
                            next
                        end
                        case field['name']
                        when 'Placer Order Number' then
                            # オーダー番号
                            identifier = FHIR::Identifier.new()
                            identifier.system = 'OID:1.2.392.100495.20.3.11'
                            identifier.value = field['value']
                            medication_request.identifier.push(identifier)
                        when 'Placer Group Number' then
                            # RP番号
                            identifier = FHIR::Identifier.new()
                            identifier.system = 'OID:1.2.392.100495.20.3.81'
                            identifier.value = field['value']
                            medication_request.identifier.push(identifier)
                        when 'Date/Time of Transaction' then
                            # 交付年月日
                            medication_request.authoredOn = Date.parse(field['value'])
                        end
                    end
                when 'RXE' then
                    segment.select{|c| 
                        Array[
                            "Give Code",
                            "Give Amount - Minimum",
                            "Give Units",
                            "Give Dosage Form",
                            "Provider's Administration Instructions",
                            "Dispense Units",
                            "Give Indication",
                            "Total Daily Dose",
                        ].include?(c['name'])
                    }.each do |field|
                        if ignore_fields?(field) then
                            next
                        end
                        case field['name']
                        when 'Give Code' then
                            # 与薬コード
                            codeable_concept = get_codeable_concept(field['array_data'].first)
                            codeable_concept.coding.system =
                                case codeable_concept.coding.system
                                when 'HOT' then 'OID:1.2.392.100495.20.2.74'
                                when 'YJ' then 'OID:1.2.392.100495.20.2.73'
                                else codeable_concept.coding.system
                                end
                            medication_request.medicationCodeableConcept = codeable_concept
                        when 'Give Amount - Minimum' then
                            # 与薬量－最小
                            quantity = FHIR::Quantity.new()
                            quantity.value = field['value']
                            dosage.doseAndRate = quantity
                        when 'Give Units' then
                            # 与薬単位
                            quantity = dosage.doseAndRate                            
                            codeable_concept = get_codeable_concept(field['array_data'].first)
                            quantity.code = codeable_concept.coding.code
                            quantity.unit = codeable_concept.coding.display
                        when 'Give Dosage Form' then
                            # 与薬剤型
                            codeable_concept = get_codeable_concept(field['array_data'].first)
                            coding = FHIR::Coding.new()
                            coding.system = 'OID:1.2.392.100495.20.2.21'
                            case codeable_concept.coding.code
                            when 'TAB','CAP','PWD','SYR' then
                                coding.code = '1'
                                coding.display = '内服'
                            when 'SUP','LQD','OIT','CRM','TPE' then
                                coding.code = '3'
                                coding.display = '外用'
                            when 'INJ' then
                                coding.code = '5'
                                coding.display = '注射'
                            else
                                coding.code = '9'
                                coding.display = 'その他'
                                codeable_concept.text = codeable_concept.coding.displey
                            end
                            codeable_concept.coding = coding
                            medication_request.category = codeable_concept
                        when 'Total Daily Dose' then
                            # 1日あたりの総投与量
                            if medication_request.dispenseRequest.nil? then
                                dispense_request = FHIR::MedicationRequest::DispenseRequest.new()
                                quantity = FHIR::Quantity.new()
                            else
                                dispense_request = medication_request.dispenseRequest
                                quantity = dispense_request.quantity
                            end
                            quantity.value = field['value']
                            dispense_request.quantity = quantity
                            medication_request.dispenseRequest = dispense_request
                        when 'Dispense Units' then
                            # 調剤単位
                            if medication_request.dispenseRequest.nil? then
                                dispense_request = FHIR::MedicationRequest::DispenseRequest.new()
                                quantity = FHIR::Quantity.new()
                            else
                                dispense_request = medication_request.dispenseRequest
                                quantity = dispense_request.quantity
                            end
                            codeable_concept = get_codeable_concept(field['array_data'].first)
                            quantity.code = codeable_concept.coding.code
                            quantity.unit = codeable_concept.coding.display
                            dispense_request.quantity = quantity
                            medication_request.dispenseRequest = dispense_request
                        end
                    end
                when 'TQ1' then                    
                    timing = FHIR::Timing.new()
                    segment.select{|c| 
                        Array[
                            "Repeat Pattern",
                            "Service Duration",
                        ].include?(c['name'])
                    }.each do |field|
                        if ignore_fields?(field) then
                            next
                        end
                        case field['name']
                        when 'Repeat Pattern' then
                            # 用法
                            field['array_data'].first.select{|c| 
                                c['name'] == 'Repeat Pattern Code'
                            }.each do |element|
                                timing.code = get_codeable_concept(element['array_data'])
                            end
                        when 'Service Duration' then
                            timing_repeat = FHIR::Timing::Repeat.new()

                            # 投与日数／投与回数
                            field['array_data'].first.select{|c| 
                                Array[
                                    "Quantity",
                                    "Units",
                                ].include?(c['name'])
                            }.each do |element|
                                case element['name']
                                when 'Quantity' then
                                    # 投薬日数／回数
                                    timing_repeat.period = element['value']
                                when 'Units' then
                                    # 投薬日数／回数単位
                                    timing_repeat.periodUnit = 
                                        case element['value']
                                        when '日分' then 'd' # 投薬日数
                                        when '回分' then '1' # 投薬回数等
                                        end
                                end
                            end
                            timing.repeat = timing_repeat
                        end
                    end
                    dosage.timing = timing
                end
            end
            medication_request.dosageInstruction = dosage
            entry = FHIR::Bundle::Entry.new()
            entry.resource = medication_request
            result.push(entry)
        end
        return result
    end
end