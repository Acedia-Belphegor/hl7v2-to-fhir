# encoding: UTF-8
require_relative 'generate_abstract'

class GenerateMedicationRequestInjection < GenerateAbstract
    def perform()
        result = Array[]
         get_segments_group().each do |segments|
            medication_request = FHIR::MedicationRequest.new()
            medication_request.id = result.length.to_s
            medication_request.status = 'draft'
            medication_request.intent = 'order'
            medication = FHIR::Medication.new()
            medication.id = medication_request.id
            dosage = FHIR::Dosage.new()
            # ORC
            segments.select{|c| c[0]['value'] == 'ORC'}.first.select{|c| 
                Array[
                    "Placer Order Number",
                    "Placer Group Number",
                    "Date/Time of Transaction",
                    "Entered By",
                    "Ordering Provider",
                    "Order Type",
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
                when 'Entered By' then
                    # ORC-10.入力者
                    
                when 'Ordering Provider' then
                    # ORC-12.依頼者
                    identifier = generate_identifier_from_xcn(field['array_data'].first)
                    # 参照
                    get_resources_from_identifier('PractitionerRole', identifier).each do |entry|
                        medication_request.requester = create_reference(entry)
                    end
                when 'Order Type' then
                    # ORC-29.オーダタイプ
                    medication_request.category.push(generate_codeable_concept(field['array_data'].first))
                end
            end
            # RXE
            segments.select{|c| c[0]['value'] == 'RXE'}.first.select{|c| 
                Array[
                    "Give Amount - Minimum",
                    "Give Amount - Maximum",
                    "Give Units",
                    "Give Dosage Form",
                    "Provider's Administration Instructions",
                    "Ordering Provider's DEA Number",
                    "Give Indication",
                    "Prescription Number",
                    "Pharmacy/Treatment Supplier's Special Dispensing Instructions",
                    "Give Rate Amount",
                    "Give Rate Units",
                    "Give Indication",
                    "Deliver-to Patient Location",
                ].include?(c['name'])
            }.each do |field|
                if ignore_fields?(field) then
                    next
                end
                case field['name']
                when 'Give Amount - Minimum' then
                    # RXE-3.与薬量－最小
                    if field['value'].empty? then
                        next
                    end
                    if field['value'].to_i > 0 then
                        medication.amount = FHIR::Ratio.new() if medication.amount.nil?
                        quantity = FHIR::Quantity.new()
                        quantity.value = field['value'].to_i
                        medication.amount.numerator = quantity
                    end
                when 'Give Amount - Maximum' then
                    # RXE-4.与薬量－最大
                    if field['value'].empty? then
                        next
                    end
                    if field['value'].to_i > 0 then
                        medication.amount = FHIR::Ratio.new() if medication.amount.nil?
                        quantity = FHIR::Quantity.new()
                        quantity.value = field['value'].to_i
                        medication.amount.denominator = quantity
                    end
                when 'Give Units' then
                    # RXE-5.与薬単位
                    codeable_concept = generate_codeable_concept(field['array_data'].first)
                    # numerator
                    if !medication.amount.numerator.nil? then
                        quantity = medication.amount.numerator
                        quantity.code = codeable_concept.coding.first.code
                        quantity.unit = codeable_concept.coding.first.display
                    end
                    # denominator
                    if !medication.amount.denominator.nil? then
                        quantity = medication.amount.denominator
                        quantity.code = codeable_concept.coding.first.code
                        quantity.unit = codeable_concept.coding.first.display
                    end
                when 'Give Dosage Form' then
                    # RXE-6.与薬剤型
                    medication.form = generate_codeable_concept(field['array_data'].first)
                when "Provider's Administration Instructions" then
                    # RXE-7.依頼者の投薬指示
                    field['array_data'].each do |record|
                        dosage.additionalInstruction.push(generate_codeable_concept(record))
                    end
                when 'Prescription Number' then
                    # RXE-15.処方箋番号
                    if !field['value'].empty? then
                        identifier = FHIR::Identifier.new()
                        identifier.system = 'OID:1.2.392.100495.20.3.11'
                        identifier.value = field['value']
                        medication_request.identifier.push(identifier)
                    end
                when "Pharmacy/Treatment Supplier's Special Dispensing Instructions" then
                    # RXE-21.薬剤部門/治療部門による特別な調剤指示
                    field['array_data'].each do |record|
                        medication_request.category.push(generate_codeable_concept(record))
                    end
                when 'Give Rate Amount' then
                    # RXE-23.与薬速度
                    if field['value'].empty?
                        next
                    end
                    if field['value'].to_i > 0 then
                        quantity = FHIR::Quantity.new()
                        quantity.value = field['value'].to_i
                        dose_and_rate = FHIR::Dosage::DoseAndRate.new()
                        dose_and_rate.type = create_codeable_concept(field['name'], field['ja_name'])
                        dose_and_rate.rateQuantity = quantity
                        dosage.doseAndRate.push(dose_and_rate)
                    end
                when 'Give Rate Units' then
                    # RXE-24.与薬速度単位
                    if dosage.doseAndRate.nil? then
                        next
                    end
                    dosage.doseAndRate.select{|c| c.type.coding.first.code == 'Give Rate Amount'}.each do |record|
                        quantity = record.rateQuantity
                        codeable_concept = generate_codeable_concept(field['array_data'].first)
                        quantity.code = codeable_concept.coding.first.code
                        quantity.unit = codeable_concept.coding.first.display    
                    end
                when 'Give Indication' then
                    # RXE-27.与薬指示
                    medication_request.category.push(generate_codeable_concept(field['array_data'].first))
                when 'Deliver-to Patient Location' then
                    # RXE-42.患者への配達場所

                end
            end
            # TQ1
            timing = FHIR::Timing.new()
            timing.repeat = FHIR::Timing::Repeat.new()
            timing.repeat.boundsPeriod = FHIR::Period.new()
            segments.select{|c| c[0]['value'] == 'TQ1'}.first.select{|c| 
                Array[
                    "Repeat Pattern",
                    "Start date/time",
                    "End date/time",
                    "Priority",
                ].include?(c['name'])
            }.each do |field|
                if ignore_fields?(field) then
                    next
                end
                case field['name']
                when 'Repeat Pattern' then
                    # TQ1-3.繰返しパターン
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
                        end
                    end
                when 'Start date/time' then
                    # TQ1-7.開始日時
                    timing.repeat.boundsPeriod.start = DateTime.parse(field['value'])
                when 'End date/time' then
                    # TQ1-8.終了日時
                    timing.repeat.boundsPeriod.end = DateTime.parse(field['value'])
                when 'Priority' then
                    # TQ1-9.優先度
                    priority = generate_codeable_concept(field['array_data'].first)
                    if priority.coding.first.system == 'HL70485' then
                        medication_request.priority = 
                            case priority.coding.first.code
                            when 'S' then 'stat'
                            when 'A' then 'asap'
                            when 'R' then 'routine'
                            end
                    end
                end
            end
            dosage.timing = timing
            # RXR
            segments.select{|c| c[0]['value'] == 'RXR'}.first.select{|c| 
                Array[
                    "Route",
                    "Administration Site",
                    "Administration Method",
                    "Routing Instruction",
                    "Administration Site Modifier",
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
                when 'Administration Method' then
                    # RXR-4.投薬方法
                    dosage.local_method = generate_codeable_concept(field['array_data'].first)
                when 'Routing Instruction' then
                    # RXR-5.経路指示
                    dosage.additionalInstruction.push(generate_codeable_concept(field['array_data'].first))
                when 'Administration Site Modifier' then
                    # RXR-6.投薬現場モディファイア
                    dosage.additionalInstruction.push(generate_codeable_concept(field['array_data'].first))
                end
            end
            # RXC
            segments.select{|c| c[0]['value'] == 'RXC'}.each do |segment|
                ingredient = FHIR::Medication::Ingredient.new()
                ratio = FHIR::Ratio.new()
                segment.select{|c| 
                    Array[
                        "RX Component Type",
                        "Component Code",
                        "Component Amount",
                        "Component Units",
                        "Supplementary Code",
                    ].include?(c['name'])
                }.each do |field|
                    if ignore_fields?(field) then
                        next
                    end
                    case field['name']
                    when "RX Component Type" then
                        # RXC-1.RX 成分タイプ
                    when "Component Code" then
                        # RXC-2.成分コード
                        codeable_concept = generate_codeable_concept(field['array_data'].first)
                        codeable_concept.coding.first.system =
                            case codeable_concept.coding.first.system
                            when 'HOT' then 'OID:1.2.392.100495.20.2.74' # HOTコード
                            when 'YJ' then 'OID:1.2.392.100495.20.2.73' # YJコード
                            else codeable_concept.coding.first.system
                            end
                            ingredient.itemCodeableConcept = codeable_concept
                    when "Component Amount" then
                        # RXC-3.成分量
                        if field['value'].empty?
                            next
                        end
                        if field['value'].to_i > 0 then
                            quantity = FHIR::Quantity.new()
                            quantity.value = field['value'].to_i
                            ratio.denominator = quantity
                        end
                    when "Component Units" then
                        # RXC-4.成分単位
                        if ratio.denominator.nil? then
                            next
                        end
                        quantity = ratio.denominator
                        codeable_concept = generate_codeable_concept(field['array_data'].first)
                        quantity.code = codeable_concept.coding.first.code
                        quantity.unit = codeable_concept.coding.first.display    
                    when "Supplementary Code" then
                        # RXC-7.補足コード
                    end
                end
                ingredient.strength = ratio
                medication.ingredient.push(ingredient)
            end
            medication_request.contained.push(medication)
            medication_request.dosageInstruction.push(dosage)
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
                medication_request.insurance.push(create_reference(entry))
            end        
            entry = FHIR::Bundle::Entry.new()
            entry.resource = medication_request
            result.push(entry)            
        end
        return result
    end

    def get_segments_group()
        segments_group = Array[]
        segments = Array[]

        # ORC,RXE,TQ1,RXR,RXCを1つのグループにまとめて配列を生成する
        @parser.get_parsed_message().select{|c| 
            Array['ORC','RXE','TQ1','RXR','RXC'].include?(c[0]['value'])
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