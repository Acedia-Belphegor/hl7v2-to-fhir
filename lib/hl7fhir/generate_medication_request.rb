# encoding: UTF-8
require_relative 'generate_abstract'

class GenerateMedicationRequest < GenerateAbstract
    def perform()
        result = Array[]
        get_segments_group().each do |segments|
            medication_request = FHIR::MedicationRequest.new()
            medication_request.id = result.length.to_s
            medication_request.status = 'draft'
            medication_request.intent = 'order'
            dosage = FHIR::Dosage.new()
            segments.each do |segment|
                case segment[0]['value']
                when 'ORC' then
                    segment.select{|c| 
                        Array[
                            "Placer Order Number",
                            "Placer Group Number",
                            "Date/Time of Transaction",
                            "Ordering Provider",
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
                        when 'Ordering Provider' then
                            # ORC-12.依頼者
                            identifier = generate_identifier_from_xcn(field['array_data'].first)
                            # 参照
                            get_resources_from_identifier('PractitionerRole', identifier).each do |entry|
                                medication_request.requester = create_reference(entry)
                            end
                        end
                    end
                when 'RXE' then
                    segment.select{|c| 
                        Array[
                            "Give Code",
                            "Give Amount - Minimum",
                            "Give Amount - Maximum",
                            "Give Units",
                            "Give Dosage Form",
                            "Provider's Administration Instructions",
                            "Dispense Amount",
                            "Dispense Units",
                            "Give Indication",
                            "Total Daily Dose",
                            "Pharmacy/Treatment Supplier's Special Dispensing Instructions",
                            "Give Indication",
                        ].include?(c['name'])
                    }.each do |field|
                        if ignore_fields?(field) then
                            next
                        end
                        case field['name']
                        when 'Give Code' then
                            # RXE-2.与薬コード
                            codeable_concept = generate_codeable_concept(field['array_data'].first)
                            codeable_concept.coding.first.system =
                                case codeable_concept.coding.first.system
                                when 'HOT' then 'OID:1.2.392.100495.20.2.74' # HOTコード
                                when 'YJ' then 'OID:1.2.392.100495.20.2.73' # YJコード
                                else codeable_concept.coding.first.system
                                end
                            medication_request.medicationCodeableConcept = codeable_concept
                        when 'Give Amount - Minimum','Give Amount - Maximum' then
                            # RXE-3.与薬量－最小 / RXE-4.与薬量－最大
                            if field['value'].empty?
                                next
                            end
                            quantity = FHIR::Quantity.new()
                            quantity.value = field['value'].to_i
                            dose_and_rate = FHIR::Dosage::DoseAndRate.new()
                            dose_and_rate.type = create_codeable_concept(field['name'], field['ja_name'])
                            dose_and_rate.doseQuantity = quantity
                            dosage.doseAndRate.push(dose_and_rate)
                        when 'Give Units' then
                            # RXE-5.与薬単位
                            if dosage.doseAndRate.nil? then
                                next
                            end
                            dosage.doseAndRate.each do |record|
                                quantity = record.doseQuantity
                                codeable_concept = generate_codeable_concept(field['array_data'].first)
                                quantity.code = codeable_concept.coding.first.code
                                quantity.unit = codeable_concept.coding.first.display    
                            end
                        when 'Give Dosage Form' then
                            # RXE-6.与薬剤型
                            codeable_concept = generate_codeable_concept(field['array_data'].first)
                            medication_request.category.push(codeable_concept)
                        when "Provider's Administration Instructions" then
                            # RXE-7.依頼者の投薬指示
                            field['array_data'].each do |record|
                                dosage.additionalInstruction.push(generate_codeable_concept(record))
                            end
                        when 'Dispense Amount' then
                            # RXE-10.調剤量
                            dispense_request = FHIR::MedicationRequest::DispenseRequest.new()
                            quantity = FHIR::Quantity.new()
                            quantity.value = field['value'].to_i
                            dispense_request.quantity = quantity
                            medication_request.dispenseRequest = dispense_request
                        when 'Dispense Units' then
                            # RXE-11.調剤単位
                            dispense_request = medication_request.dispenseRequest
                            quantity = dispense_request.quantity
                            codeable_concept = generate_codeable_concept(field['array_data'].first)
                            quantity.code = codeable_concept.coding.first.code
                            quantity.unit = codeable_concept.coding.first.display
                        when 'Total Daily Dose' then
                            # RXE-19.1日あたりの総投与量
                            quantity = FHIR::Quantity.new()
                            dose_and_rate = FHIR::Dosage::DoseAndRate.new()
                            dose_and_rate.type = create_codeable_concept(field['name'], field['ja_name'])
                            dose_and_rate.doseQuantity = generate_quantity(field['array_data'].first)
                            dosage.doseAndRate.push(dose_and_rate)
                        when "Pharmacy/Treatment Supplier's Special Dispensing Instructions" then
                            # RXE-21.薬剤部門/治療部門による特別な調剤指示
                            
                        when 'Give Indication' then
                            # RXE-27.与薬指示
                            codeable_concept = generate_codeable_concept(field['array_data'].first)
                            medication_request.category.push(codeable_concept)
                        end
                    end
                when 'TQ1' then                    
                    timing = FHIR::Timing.new()
                    dosage.text = ''
                    segment.select{|c| 
                        Array[
                            "Repeat Pattern",
                            "Service Duration",
                            "Start date/time",
                            "Text instruction",
                        ].include?(c['name'])
                    }.each do |field|
                        if ignore_fields?(field) then
                            next
                        end
                        case field['name']
                        when 'Repeat Pattern' then
                            # TQ1-3.繰返しパターン(用法)
                            field['array_data'].each do |record|
                                record.select{|c| 
                                    c['name'] == 'Repeat Pattern Code'
                                }.each do |element|
                                    codeable_concept = generate_codeable_concept(element['array_data'])
                                    if timing.code.nil? then
                                        timing.code = Array[codeable_concept]
                                    else
                                        dosage.additionalInstruction.push(codeable_concept)
                                    end
                                    # 可読部の編集
                                    dosage.text += "　" if !dosage.text.empty?
                                    dosage.text += codeable_concept.coding.first.display
                                end
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
                                    timing_repeat.period = element['value'].to_i
                                when 'Units' then
                                    if element['array_data'].nil? then
                                        period_unit = element['value']
                                    else
                                        codeable_concept = generate_codeable_concept(element['array_data'])
                                        period_unit = codeable_concept.coding.first.code
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
                        when 'Start date/time' then
                            # TQ1-7.開始日時
                            timing.event = Array[parse_str_datetime(field['value'])]
                        when 'Text instruction' then
                            # TQ1-11.テキスト指令
                            dosage.patientInstruction = field['value']
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
                            dosage.route = generate_codeable_concept(field['array_data'].first)
                        when 'Administration Site' then
                            # RXR-2.部位
                            dosage.site = generate_codeable_concept(field['array_data'].first)
                        end
                    end
                end
            end
            medication_request.dosageInstruction.push(dosage)
            # 患者の参照
            get_resources_from_type('Patient').each do |entry|
                medication_request.subject = create_reference(entry)
            end
            # 保険の参照
            get_resources_from_type('Coverage').each do |entry|
                medication_request.insurance.push(create_reference(entry))
            end
            # # 処方医の参照
            # get_resources_from_type('PractitionerRole').select{|c|
            #     c.resource.code.coding.first.code == 'doctor'
            # }.each do |entry|
            #     medication_request.requester = entry.resource.practitioner
            # end
            entry = FHIR::Bundle::Entry.new()
            entry.resource = medication_request
            result.push(entry)
        end
        return result
    end

    def get_segments_group()
        segments_group = Array[]
        segments = Array[]

        # ORC,RXE,TQ1,RXRを1つのグループにまとめて配列を生成する
        @parser.get_parsed_message().select{|c| 
            Array['ORC','RXE','TQ1','RXR'].include?(c[0]['value'])
        }.each do |segment|
            # ORCの出現を契機に配列を作成する
            if segment[0]['value'] == 'ORC' then
                segments_group.push(segments) if !segments.empty?
                segments = Array[]
            end
            segments.push(segment)
        end
        segments_group.push(segments) if !segments.empty?
    end
end