# encoding: UTF-8
require_relative 'generate_abstract'

class GenerateMedicationRequestInjection < GenerateAbstract
    def perform()
        results = []
         get_segments_group.each do |segments|
            medication_request = FHIR::MedicationRequest.new
            medication_request.id = SecureRandom.uuid
            medication_request.status = :draft
            medication_request.intent = :order
            medication = FHIR::Medication.new
            medication.id = medication_request.id
            dosage = FHIR::Dosage.new
            # ORC
            segments.select{|c| c[0]['value'] == 'ORC'}.first.select{|c| 
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
                    identifier.value = field['value']
                    medication_request.identifier << identifier
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
            # RXE
            segments.select{|c| c[0]['value'] == 'RXE'}.first.select{|c| 
                [
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
                next if ignore_fields?(field)
                case field['name']
                when 'Give Amount - Minimum'
                    # RXE-3.与薬量－最小
                    next if field['value'].empty?
                    if field['value'].to_i.positive?
                        medication.amount = FHIR::Ratio.new if medication.amount.nil?
                        quantity = FHIR::Quantity.new
                        quantity.value = field['value'].to_i
                        medication.amount.numerator = quantity
                    end
                when 'Give Amount - Maximum'
                    # RXE-4.与薬量－最大
                    next if field['value'].empty?                        
                    if field['value'].to_i.positive?
                        medication.amount = FHIR::Ratio.new if medication.amount.nil?
                        quantity = FHIR::Quantity.new
                        quantity.value = field['value'].to_i
                        medication.amount.denominator = quantity
                    end
                when 'Give Units'
                    # RXE-5.与薬単位
                    codeable_concept = generate_codeable_concept(field['array_data'].first)
                    # numerator
                    if medication.amount.numerator.present?
                        quantity = medication.amount.numerator
                        quantity.code = codeable_concept.coding.first.code
                        quantity.unit = codeable_concept.coding.first.display
                    end
                    # denominator
                    if medication.amount.denominator.present?
                        quantity = medication.amount.denominator
                        quantity.code = codeable_concept.coding.first.code
                        quantity.unit = codeable_concept.coding.first.display
                    end
                when 'Give Dosage Form'
                    # RXE-6.与薬剤型
                    medication.form = generate_codeable_concept(field['array_data'].first)
                when "Provider's Administration Instructions"
                    # RXE-7.依頼者の投薬指示
                    field['array_data'].each do |record|
                        dosage.additionalInstruction << generate_codeable_concept(record)
                    end
                when 'Prescription Number'
                    # RXE-15.処方箋番号
                    if field['value'].present?
                        identifier = FHIR::Identifier.new
                        identifier.system = 'urn:oid:1.2.392.100495.20.3.11'
                        identifier.value = field['value']
                        medication_request.identifier << identifier
                    end
                when "Pharmacy/Treatment Supplier's Special Dispensing Instructions"
                    # RXE-21.薬剤部門/治療部門による特別な調剤指示
                    field['array_data'].each do |record|
                        medication_request.category << generate_codeable_concept(record)
                    end
                when 'Give Rate Amount'
                    # RXE-23.与薬速度
                    next if field['value'].empty?
                    if field['value'].to_i.positive?
                        quantity = FHIR::Quantity.new
                        quantity.value = field['value'].to_i
                        dose_and_rate = FHIR::Dosage::DoseAndRate.new
                        dose_and_rate.type = create_codeable_concept(field['name'], field['ja_name'])
                        dose_and_rate.rateQuantity = quantity
                        dosage.doseAndRate << dose_and_rate
                    end
                when 'Give Rate Units'
                    # RXE-24.与薬速度単位
                    next if dosage.doseAndRate.nil?
                    dosage.doseAndRate.select{|c| c.type.coding.first.code == 'Give Rate Amount'}.each do |record|
                        quantity = record.rateQuantity
                        codeable_concept = generate_codeable_concept(field['array_data'].first)
                        quantity.code = codeable_concept.coding.first.code
                        quantity.unit = codeable_concept.coding.first.display    
                    end
                when 'Give Indication'
                    # RXE-27.与薬指示
                    medication_request.category << generate_codeable_concept(field['array_data'].first)
                when 'Deliver-to Patient Location'
                    # RXE-42.患者への配達場所
                end
            end
            # TQ1
            timing = FHIR::Timing.new
            timing.repeat = FHIR::Timing::Repeat.new
            timing.repeat.boundsPeriod = FHIR::Period.new
            segments.select{|c| c[0]['value'] == 'TQ1'}.first.select{|c| 
                [
                    "Repeat Pattern",
                    "Start date/time",
                    "End date/time",
                    "Priority",
                ].include?(c['name'])
            }.each do |field|
                next if ignore_fields?(field)
                case field['name']
                when 'Repeat Pattern'
                    # TQ1-3.繰返しパターン
                    field['array_data'].each do |record|
                        record.select{ |c| c['name'] == 'Repeat Pattern Code' }.each do |element|
                            codeable_concept = generate_codeable_concept(element['array_data'])
                            timing.code.nil? ? timing.code = [codeable_concept] : dosage.additionalInstruction << codeable_concept
                        end
                    end
                when 'Start date/time'
                    # TQ1-7.開始日時
                    timing.repeat.boundsPeriod.start = DateTime.parse(field['value'])
                when 'End date/time'
                    # TQ1-8.終了日時
                    timing.repeat.boundsPeriod.end = DateTime.parse(field['value'])
                when 'Priority'
                    # TQ1-9.優先度
                    priority = generate_codeable_concept(field['array_data'].first)
                    if priority.coding.first.system == 'HL70485'
                        medication_request.priority = 
                            case priority.coding.first.code
                            when 'S' then :stat
                            when 'A' then :asap
                            when 'R' then :routine
                            end
                    end
                end
            end
            dosage.timing = timing
            # RXR
            segments.select{|c| c[0]['value'] == 'RXR'}.first.select{|c| 
                [
                    "Route",
                    "Administration Site",
                    "Administration Method",
                    "Routing Instruction",
                    "Administration Site Modifier",
                ].include?(c['name'])
            }.each do |field|
                next if ignore_fields?(field)
                case field['name']
                when 'Route'
                    # RXR-1.経路
                    dosage.route = generate_codeable_concept(field['array_data'].first)
                when 'Administration Site'
                    # RXR-2.部位
                    dosage.site = generate_codeable_concept(field['array_data'].first)
                when 'Administration Method'
                    # RXR-4.投薬方法
                    dosage.local_method = generate_codeable_concept(field['array_data'].first)
                when 'Routing Instruction'
                    # RXR-5.経路指示
                    dosage.additionalInstruction << generate_codeable_concept(field['array_data'].first)
                when 'Administration Site Modifier'
                    # RXR-6.投薬現場モディファイア
                    dosage.additionalInstruction << generate_codeable_concept(field['array_data'].first)
                end
            end
            # RXC
            segments.select{|c| c[0]['value'] == 'RXC'}.each do |segment|
                ingredient = FHIR::Medication::Ingredient.new
                ratio = FHIR::Ratio.new
                segment.select{|c| 
                    [
                        "RX Component Type",
                        "Component Code",
                        "Component Amount",
                        "Component Units",
                        "Supplementary Code",
                    ].include?(c['name'])
                }.each do |field|
                    next if ignore_fields?(field)
                    case field['name']
                    when "RX Component Type"
                        # RXC-1.RX 成分タイプ
                    when "Component Code"
                        # RXC-2.成分コード
                        codeable_concept = generate_codeable_concept(field['array_data'].first)
                        codeable_concept.coding.first.system =
                            case codeable_concept.coding.first.system
                            when 'HOT' then 'urn:oid:1.2.392.100495.20.2.74' # HOTコード
                            when 'YJ' then 'urn:oid:1.2.392.100495.20.2.73' # YJコード
                            else codeable_concept.coding.first.system
                            end
                            ingredient.itemCodeableConcept = codeable_concept
                    when "Component Amount"
                        # RXC-3.成分量
                        next if field['value'].empty?
                        if field['value'].to_i.positive?
                            quantity = FHIR::Quantity.new
                            quantity.value = field['value'].to_i
                            ratio.denominator = quantity
                        end
                    when "Component Units"
                        # RXC-4.成分単位
                        next if ratio.denominator.nil?                            
                        quantity = ratio.denominator
                        codeable_concept = generate_codeable_concept(field['array_data'].first)
                        quantity.code = codeable_concept.coding.first.code
                        quantity.unit = codeable_concept.coding.first.display    
                    when "Supplementary Code"
                        # RXC-7.補足コード
                    end
                end
                ingredient.strength = ratio
                medication.ingredient << ingredient
            end
            medication_request.contained << medication
            medication_request.dosageInstruction << dosage
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

    def get_segments_group()
        segments_group = []
        segments = []

        # ORC,RXE,TQ1,RXR,RXCを1つのグループにまとめて配列を生成する
        @parser.get_parsed_message.select{ |c| ['ORC','RXE','TQ1','RXR','RXC'].include?(c[0]['value']) }.each do |segment|
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