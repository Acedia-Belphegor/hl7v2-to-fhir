# encoding: UTF-8
require_relative 'generate_abstract'

class GenerateMedicationRequestPrescription < GenerateAbstract
    def perform()
        results = []
        get_segments_group.each do |segments|
            medication_request = FHIR::MedicationRequest.new
            medication_request.id = SecureRandom.uuid
            medication_request.status = :draft
            medication_request.intent = :order
            medication = FHIR::Medication.new
            medication.id = SecureRandom.uuid
            dosage = FHIR::Dosage.new            
            segments.each do |segment|
                case segment[0]['value']
                when 'ORC'
                    segment.select{|c| 
                        [
                            "Placer Order Number",
                            "Placer Group Number",
                            "Date/Time of Transaction",
                            "Entered By",
                            "Ordering Provider",
                            "Order Type",
                        ].include?(c['name'])
                    }.each do |field|
                        next if ignore_fields?(field)
                        case field['name']
                        when 'Placer Order Number'
                            # ORC-2.依頼者オーダ番号
                            identifier = FHIR::Identifier.new
                            identifier.system = 'urn:oid:1.2.392.100495.20.3.11'
                            identifier.value = field['value']
                            medication_request.identifier << identifier
                        when 'Placer Group Number'
                            # ORC-4.依頼者グループ番号
                            identifier = FHIR::Identifier.new
                            identifier.system = 'urn:oid:1.2.392.100495.20.3.81'
                            identifier.value = field['value'].match(/(?:^|(?<=_))(?!.*_).+$/).to_s # アンダースコアで区切られた最後の文字を取得する
                            # medication_request.identifier << identifier
                            medication_request.groupIdentifier = identifier
                        when 'Date/Time of Transaction'
                            # ORC-9.トランザクション日時(交付年月日)
                            medication_request.authoredOn = Date.parse(field['value'])
                        when 'Entered By'
                            # ORC-10.入力者
                        when 'Ordering Provider'
                            # ORC-12.依頼者
                            identifier = generate_identifier_from_xcn(field['array_data'].first)
                            # 参照
                            get_resources_from_identifier('Practitioner', identifier).each do |entry|
                                medication_request.requester = create_reference(entry)
                            end
                        when 'Order Type'
                            # ORC-29.オーダタイプ
                            medication_request.category << generate_codeable_concept(field['array_data'].first)
                        end
                    end
                when 'RXE'
                    segment.select{|c| 
                        [
                            "Give Code",
                            "Give Amount - Minimum",
                            # "Give Amount - Maximum",
                            "Give Units",
                            "Give Dosage Form",
                            "Provider's Administration Instructions",
                            "Dispense Amount",
                            "Dispense Units",
                            "Give Indication",
                            "Prescription Number",
                            "Total Daily Dose",
                            "Pharmacy/Treatment Supplier's Special Dispensing Instructions",
                            "Give Indication",
                        ].include?(c['name'])
                    }.each do |field|
                        next if ignore_fields?(field)
                        case field['name']
                        when 'Give Code'
                            # RXE-2.与薬コード
                            codeable_concept = generate_codeable_concept(field['array_data'].first)
                            if codeable_concept.coding.first.system == 'HOT'
                                codeable_concept.coding.first.system = 'urn:oid:1.2.392.100495.20.2.74' # HOTコード
                            end
                            # medication_request.medicationCodeableConcept = codeable_concept
                            medication.code = codeable_concept

                        # when 'Give Amount - Minimum','Give Amount - Maximum'
                        #     # RXE-3.与薬量－最小 / RXE-4.与薬量－最大
                        #     next if field['value'].empty?
                        #     if field['value'].to_i.positive?
                        #         quantity = FHIR::Quantity.new
                        #         quantity.value = field['value'].to_i
                        #         dose = FHIR::Dosage::DoseAndRate.new
                        #         dose.type = create_codeable_concept(field['name'], field['ja_name'])
                        #         dose.doseQuantity = quantity
                        #         dosage.doseAndRate << dose
                        #     end
                        when 'Give Amount - Minimum'
                            # RXE-3.与薬量－最小
                            next if field['value'].empty?
                            if field['value'].to_i.positive?
                                quantity = FHIR::Quantity.new
                                quantity.value = field['value'].to_i
                                dose = FHIR::Dosage::DoseAndRate.new
                                dose.doseQuantity = quantity
                                dosage.doseAndRate << dose
                            end
                        when 'Give Units'
                            # RXE-5.与薬単位
                            next if dosage.doseAndRate.nil?
                            dosage.doseAndRate.each do |record|
                                quantity = record.doseQuantity
                                codeable_concept = generate_codeable_concept(field['array_data'].first)
                                quantity.code = codeable_concept.coding.first.code
                                quantity.unit = codeable_concept.coding.first.display    
                            end
                        when 'Give Dosage Form'
                            # RXE-6.与薬剤型
                            # codeable_concept = generate_codeable_concept(field['array_data'].first)
                            # medication_request.category << codeable_concept
                            medication.form = generate_codeable_concept(field['array_data'].first)
                        when "Provider's Administration Instructions"
                            # RXE-7.依頼者の投薬指示
                            field['array_data'].each do |record|
                                dosage.additionalInstruction << generate_codeable_concept(record)
                            end
                        when 'Dispense Amount'
                            # RXE-10.調剤量
                            dispense_request = FHIR::MedicationRequest::DispenseRequest.new
                            quantity = FHIR::Quantity.new
                            quantity.value = field['value'].to_i
                            dispense_request.quantity = quantity
                            medication_request.dispenseRequest = dispense_request
                        when 'Dispense Units'
                            # RXE-11.調剤単位
                            dispense_request = medication_request.dispenseRequest
                            quantity = dispense_request.quantity
                            codeable_concept = generate_codeable_concept(field['array_data'].first)
                            quantity.code = codeable_concept.coding.first.code
                            quantity.unit = codeable_concept.coding.first.display
                        when 'Prescription Number'
                            # RXE-15.処方箋番号
                            if field['value'].present?
                                identifier = FHIR::Identifier.new
                                identifier.system = 'urn:oid:1.2.392.100495.20.3.11'
                                identifier.value = field['value']
                                medication_request.identifier << identifier
                            end
                        when 'Total Daily Dose'
                            # RXE-19.1日あたりの総投与量
                            extension = FHIR::Extension.new
                            extension.url = "http://hl7fhir.jp/fhir/StructureDefinition/Extension-JPCore-TotalDailyDose"
                            extension.valueQuantity = generate_quantity(field['array_data'].first)
                            dosage.extension << extension

                            # dose = FHIR::Dosage::DoseAndRate.new
                            # dose.type = create_codeable_concept(field['name'], field['ja_name'])
                            # dose.doseQuantity = generate_quantity(field['array_data'].first)
                            # dosage.doseAndRate << dose
                        when "Pharmacy/Treatment Supplier's Special Dispensing Instructions"
                            # RXE-21.薬剤部門/治療部門による特別な調剤指示
                            field['array_data'].each do |record|
                                medication_request.category << generate_codeable_concept(record)
                            end
                        when 'Give Indication'
                            # RXE-27.与薬指示
                            codeable_concept = generate_codeable_concept(field['array_data'].first)
                            medication_request.category << codeable_concept

                            if codeable_concept.coding.first.code == '22' # 頓用
                                dosage.asNeededBoolean = true
                            end
                        end
                    end
                when 'TQ1'
                    timing = FHIR::Timing.new
                    dosage.text = ''
                    segment.select{|c| 
                        [
                            "Repeat Pattern",
                            "Service Duration",
                            "Start date/time",
                            "Text instruction",
                            "Total occurrence's",
                        ].include?(c['name'])
                    }.each do |field|
                        next if ignore_fields?(field)
                        case field['name']
                        when 'Repeat Pattern'
                            # TQ1-3.繰返しパターン(用法)
                            field['array_data'].each do |record|
                                record.select{ |c| c['name'] == 'Repeat Pattern Code' }.each do |element|
                                    codeable_concept = generate_codeable_concept(element['array_data'])
                                    timing.code.nil? ? timing.code = [codeable_concept] : dosage.additionalInstruction << codeable_concept
                                    # 可読部の編集
                                    dosage.text += "　" if dosage.text.present?
                                    dosage.text += codeable_concept.coding.first.display
                                end
                            end
                        when 'Service Duration'
                            # TQ1-6.サービス期間
                            timing_repeat = FHIR::Timing::Repeat.new

                            # 投与日数／投与回数
                            field['array_data'].first.select{ |c| ["Quantity","Units"].include?(c['name']) }.each do |element|
                                case element['name']
                                when 'Quantity'
                                    # 投薬日数／回数
                                    timing_repeat.period = element['value'].to_i
                                when 'Units'
                                    period_unit = element['array_data'].present? ? generate_codeable_concept(element['array_data']).coding.first.code : element['value']
                                    # 投薬日数／回数単位
                                    timing_repeat.periodUnit = 
                                        case period_unit
                                        when '日','日分','D' then '日' # 投薬日数
                                        when '回','回分','T' then '回' # 投薬回数等
                                        end
                                end
                            end
                            timing.repeat = timing_repeat
                        when 'Start date/time'
                            # TQ1-7.開始日時
                            timing.event = [parse_str_datetime(field['value'])]
                        when 'Text instruction'
                            # TQ1-11.テキスト指令
                            dosage.patientInstruction = field['value']
                        when "Total occurrence's"
                            # TQ1-14.事象総数
                            if field['value'].present?
                                timing_repeat = FHIR::Timing::Repeat.new
                                timing_repeat.period = field['value'].to_i
                                timing_repeat.periodUnit = '回'
                                timing.repeat = timing_repeat
                            end
                        end
                    end
                    dosage.timing = timing
                when 'RXR'
                    segment.select{ |c| ["Route","Administration Site"].include?(c['name']) }.each do |field|
                        next if ignore_fields?(field)
                        case field['name']
                        when 'Route'
                            # RXR-1.経路
                            dosage.route = generate_codeable_concept(field['array_data'].first)
                        when 'Administration Site'
                            # RXR-2.部位
                            dosage.site = generate_codeable_concept(field['array_data'].first)
                        end
                    end
                end
            end
            medication_request.contained << medication
            # medication_request.dosageInstruction << dosage
            # # 不均等投与
            # imbalances = dosage.additionalInstruction.map{ |c| c.coding.select{ |c| c.code.match(/^V[1-9][0-9.N]+$/) && c.system == 'JAMISDP01' } }.compact.reject(&:empty?)
            # if imbalances.count.positive?
            #     imbalances.each do |imbalance|
            #         imbalance_dosage = Marshal.load(Marshal.dump(dosage))
            #         imbalance_dosage.timing.code = imbalance
            #         imbalance_dosage.additionalInstruction = nil
            #         imbalance_dosage.extension = nil
            #         imbalance_dosage.text = nil
            #         imbalance_dosage.sequence = imbalance.first.code.slice(1).to_i
            #         dose = imbalance_dosage.doseAndRate.first
            #         dose.doseQuantity.value = imbalance.first.code.slice(2..-1).delete('N').to_i
            #         medication_request.dosageInstruction << imbalance_dosage
            #     end
            # else
            #     medication_request.dosageInstruction << dosage
            # end

            # # 不均等投与
            # imbalances = dosage.additionalInstruction.map{ |c| c.coding.select{ |c| c.code.match(/^V[1-9][0-9.N]+$/) && c.system == 'JAMISDP01' } }.compact.reject(&:empty?)
            # if imbalances.count.positive?
                # dosage.sequence = 0
            #     medication_request.dosageInstruction << dosage
            #     imbalances.each do |imbalance|
            #         imbalance_dosage = Marshal.load(Marshal.dump(dosage))
            #         imbalance_dosage.timing.code = imbalance
            #         imbalance_dosage.timing.event = nil
            #         imbalance_dosage.timing.repeat = nil
            #         imbalance_dosage.route = nil
            #         imbalance_dosage.additionalInstruction = nil
            #         imbalance_dosage.extension = nil
            #         imbalance_dosage.text = nil
            #         imbalance_dosage.sequence = imbalance.first.code.slice(1).to_i
            #         dose = imbalance_dosage.doseAndRate.first
            #         dose.doseQuantity.value = imbalance.first.code.slice(2..-1).delete('N').to_i
            #         medication_request.dosageInstruction << imbalance_dosage
            #     end
            #     dosage.additionalInstruction = nil
            #     dosage.doseAndRate = nil
            # else
            #     medication_request.dosageInstruction << dosage
            # end

            medication_request.dosageInstruction << dosage
            # 不均等投与
            imbalances = dosage.additionalInstruction.map{ |c| c.coding.select{ |c| c.code.match(/^V[1-9][0-9.N]+$/) && c.system == 'JAMISDP01' } }.compact.reject(&:empty?)
            if imbalances.count.positive?
                imbalance_doses = []
                imbalances.each do |imbalance|
                    quantity = FHIR::Quantity.new
                    quantity.value = imbalance.first.code.slice(2..-1).delete('N').to_i
                    quantity.code = dosage.doseAndRate.first.doseQuantity.code
                    quantity.unit = dosage.doseAndRate.first.doseQuantity.unit
                    dose = FHIR::Dosage::DoseAndRate.new
                    dose.type = imbalance
                    dose.doseQuantity = quantity
                    imbalance_doses << dose
                end
                dosage.doseAndRate = imbalance_doses
                dosage.additionalInstruction.delete_if{ |c| imbalances.include?(c.coding) }
            end
            # 医薬品の参照
            medication_request.contained.each do |resource|
                medication_request.medicationReference = create_reference_from_resource(resource)
            end
            # 患者の参照
            get_resources_from_type('Patient').each do |entry|
                medication_request.subject = create_reference(entry)
            end
            # 保険の参照
            get_resources_from_type('Coverage').each do |entry|
                medication_request.insurance << create_reference(entry)
            end
            entry = FHIR::Bundle::Entry.new
            entry.resource = medication_request
            results << entry
        end
        results
    end

    private
    def get_segments_group()
        segments_group = []
        segments = []

        # ORC,RXE,TQ1,RXRを1つのグループにまとめて配列を生成する
        @parser.get_parsed_message.select{ |c| ['ORC','RXE','TQ1','RXR'].include?(c[0]['value']) }.each do |segment|
            # ORCの出現を契機に配列を作成する
            if segment[0]['value'] == 'ORC'
                segments_group << segments if segments.present?
                segments = []
            end
            segments << segment
        end
        segments_group << segments if segments.present?
    end
end