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
                            # ORC-2.依頼者オーダ番号
                            identifier = FHIR::Identifier.new()
                            identifier.system = 'OID:1.2.392.100495.20.3.11'
                            identifier.value = field['value']
                            medication_request.identifier.push(identifier)
                        when 'Placer Group Number' then
                            # ORC-4.依頼者グループ番号
                            identifier = FHIR::Identifier.new()
                            identifier.system = 'OID:1.2.392.100495.20.3.81'
                            identifier.value = field['value']
                            medication_request.identifier.push(identifier)
                        when 'Date/Time of Transaction' then
                            # ORC-9.トランザクション日時(交付年月日)
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
                            "Dispense Amount",
                            "Dispense Units",
                            "Give Indication",
                            "Total Daily Dose",
                            "Give Indication",
                        ].include?(c['name'])
                    }.each do |field|
                        if ignore_fields?(field) then
                            next
                        end
                        case field['name']
                        when 'Give Code' then
                            # RXE-2.与薬コード
                            codeable_concept = get_codeable_concept(field['array_data'].first)
                            codeable_concept.coding.system =
                                case codeable_concept.coding.system
                                when 'HOT' then 'OID:1.2.392.100495.20.2.74'
                                when 'YJ' then 'OID:1.2.392.100495.20.2.73'
                                else codeable_concept.coding.system
                                end
                            medication_request.medicationCodeableConcept = codeable_concept
                        when 'Give Amount - Minimum' then
                            # RXE-3.与薬量－最小
                            if field['value'].empty?
                                next
                            end
                            quantity = FHIR::Quantity.new()
                            quantity.value = field['value']
                            dose_and_rate = FHIR::Dosage::DoseAndRate.new()
                            codeable_concept = FHIR::CodeableConcept.new()
                            coding = FHIR::Coding.new()
                            coding.code = 'T'
                            coding.display = '１回量'
                            coding.system = 'LC'
                            codeable_concept.coding = coding
                            dose_and_rate.type = codeable_concept
                            dose_and_rate.doseQuantity = quantity
                            dosage.doseAndRate.push(dose_and_rate)
                        when 'Give Units' then
                            # RXE-5.与薬単位
                            if dosage.doseAndRate.nil? then
                                next
                            end
                            dose_and_rate = dosage.doseAndRate.first
                            quantity = dose_and_rate.doseQuantity
                            codeable_concept = get_codeable_concept(field['array_data'].first)
                            quantity.code = codeable_concept.coding.code
                            quantity.unit = codeable_concept.coding.display
                        when 'Give Dosage Form' then
                            # RXE-6.与薬剤型
                            codeable_concept = get_codeable_concept(field['array_data'].first)
                            medication_request.category.push(codeable_concept)
                        when 'Dispense Amount' then
                            # RXE-10.調剤量
                            dispense_request = FHIR::MedicationRequest::DispenseRequest.new()
                            quantity = FHIR::Quantity.new()
                            quantity.value = field['value']
                            dispense_request.quantity = quantity
                            medication_request.dispenseRequest = dispense_request
                        when 'Dispense Units' then
                            # RXE-11.調剤単位
                            dispense_request = medication_request.dispenseRequest
                            quantity = dispense_request.quantity
                            codeable_concept = get_codeable_concept(field['array_data'].first)
                            quantity.code = codeable_concept.coding.code
                            quantity.unit = codeable_concept.coding.display
                        when 'Total Daily Dose' then
                            # RXE-19.1日あたりの総投与量
                            quantity = FHIR::Quantity.new()
                            dose_and_rate = FHIR::Dosage::DoseAndRate.new()
                            codeable_concept = FHIR::CodeableConcept.new()
                            coding = FHIR::Coding.new()
                            coding.code = 'D'
                            coding.display = '１日量'
                            coding.system = 'LC'
                            codeable_concept.coding = coding
                            dose_and_rate.type = codeable_concept
                            dose_and_rate.doseQuantity = get_quantity(field['array_data'].first)
                            dosage.doseAndRate.push(dose_and_rate)
                        when 'Give Indication' then
                            # RXE-27.与薬指示
                            codeable_concept = get_codeable_concept(field['array_data'].first)
                            medication_request.category.push(codeable_concept)
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
                            # TQ1-3.繰返しパターン(用法)
                            field['array_data'].first.select{|c| 
                                c['name'] == 'Repeat Pattern Code'
                            }.each do |element|
                                timing.code = get_codeable_concept(element['array_data'])
                            end
                        when 'Service Duration' then
                            # TQ1-6.サービス期間
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
                                    if element['array_data'].nil? then
                                        period_unit = element['value']
                                    else
                                        codeable_concept = get_codeable_concept(element['array_data'])
                                        period_unit = codeable_concept.coding.code
                                    end
                                    # 投薬日数／回数単位
                                    timing_repeat.periodUnit = 
                                        case period_unit
                                        when '日','日分','D' then 'd' # 投薬日数
                                        when '回','回分' then '1' # 投薬回数等
                                        end
                                end
                            end
                            timing.repeat = timing_repeat
                        end
                    end
                    dosage.timing = timing
                when 'RXR' then
                    segment.select{|c| 
                        Array[
                            "Route",
                            "Administration Site",
                        ].include?(c['name'])
                    }.each do |field|
                        if ignore_fields?(field) then
                            next
                        end
                        case field['name']
                        when 'Route' then
                            # RXR-1.経路
                            dosage.route = get_codeable_concept(field['array_data'].first)
                        when 'Administration Site' then
                            # RXR-2.部位
                            dosage.site = get_codeable_concept(field['array_data'].first)
                        end
                    end
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