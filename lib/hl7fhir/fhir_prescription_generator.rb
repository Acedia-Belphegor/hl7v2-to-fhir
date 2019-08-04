# encoding: UTF-8
require 'json'
require 'fhir_client'
require_relative '../hl7v2/hl7parser'

class FhirPrescriptionGenerator
    def initialize(raw_message, generate: false)
        @parser = HL7Parser.new(raw_message)
        @client = FHIR::Client.new("http://localhost:8080", default_format: 'json')
        @client.use_stu3()
        FHIR::Model.client = @client

        filename = Pathname.new(File.dirname(File.expand_path(__FILE__))).join('json').join('JAHIS_TABLES.json')
        @jahis_tables = File.open(filename) do |io|
            JSON.load(io)
        end
        perform() if generate
    end

    def perform()
        @bundle = FHIR::Bundle.new()
        @bundle.type = 'message'

        # MessageHeader
        generate_message_header()

        # Patient
        generate_patient()

        # Practitioner
        generate_practitioner()

        # PractitionerRole
        generate_practitioner_role()

        # Organization
        generate_organization()

        # MedicationRequest
        generate_medication_request()

        # Coverage
        generate_coverage()

        # @bundle.create()
        # puts @bundle.id
    end

    def get_resource()
        return @bundle
    end

    private
    # MessageHeader
    def generate_message_header()
        message_header = FHIR::MessageHeader.new()

        msh_segment = @parser.get_parsed_segments('MSH')
        if msh_segment.nil? then
            return
        end

        msh_segment.first.select{|c|
            Array[
                "Sending Application",
                "Sending Facility",
                "Receiving Application",
                "Message Type",
            ].include?(c['name'])
        }.each do |field|
            case field['name']
            when 'Sending Application' then
                # 送信アプリケーション
                source = FHIR::MessageHeader::Source.new()
                source.name = field['value']
                message_header.source = source
            when 'Sending Facility' then
                # 送信施設
                sending_facility = field['value']
                if sending_facility.length == 10 then
                    @state_code = sending_facility[0,2] # 都道府県番号
                    @fee_score_code = sending_facility[2,1] # 点数表番号
                    @facility_code = sending_facility[3,7] # 医療機関コード
                end
            when 'Receiving Application' then
                # 受信アプリケーション
                destination = FHIR::MessageHeader::Destination.new()
                destination.name = field['value']
                message_header.destination = destination
            when 'Message Type' then
                # メッセージ型
                coding = FHIR::Coding.new()
                coding.code = field['value']
                coding.system = 'http://www.hl7.org'
                message_header.eventCoding = coding
            end
        end
        entry = FHIR::Bundle::Entry.new()
        entry.resource = message_header
        @bundle.entry.push(entry)
    end

    # Patient
    def generate_patient()
        patient = FHIR::Patient.new()

        pid_segment = @parser.get_parsed_segments('PID')
        if pid_segment.nil? then
            return
        end
        
        pid_segment.first.select{|c|
            Array[
                "Patient Identifier List",
                "Patient Name",
                "Date/Time of Birth",
                "Administrative Sex",
                "Patient Address",
                "Phone Number - Home",
                "Phone Number - Business",
            ].include?(c['name'])
        }.each do |field|
            if ignore_fields?(field) then
                next
            end
            case field['name']
            when 'Patient Identifier List' then
                # 患者ID
                identifier = FHIR::Identifier.new()
                identifier.system = "OID:1.2.392.100495.20.3.51.1#{get_facility_id}"
                identifier.value = field['value']
                patient.identifier = identifier
            when 'Patient Name' then
                # 患者氏名
                field['array_data'].each do |record|
                    human_name = get_human_name(record)
                    human_name.use = 'official'                    
                    patient.name.push(human_name)
                end
            when 'Date/Time of Birth' then
                # 生年月日
                patient.birthDate = Date.parse(field['value'])
            when 'Administrative Sex' then
                # 性別
                patient.gender = 
                    case field['value']
                    when 'M' then 'male'   # 男性
                    when 'F' then 'female' # 女性
                    end
            when 'Patient Address' then
                # 患者の住所
                field['array_data'].each do |record|
                    patient.address.push(get_address(record))
                end
            when 'Phone Number - Home' then
                # 電話番号-自宅
                telephone_number = get_telephone_number(field['array_data'].first)
                if !telephone_number.empty? then
                    contact_point = FHIR::ContactPoint.new()
                    contact_point.system = 'phone'
                    contact_point.value = telephone_number
                    contact_point.use = 'home'
                    patient.telecom.push(contact_point)
                end
            when 'Phone Number - Business' then
                # 電話番号-勤務先
                telephone_number = get_telephone_number(field['array_data'].first)
                if !telephone_number.empty? then
                    contact_point = FHIR::ContactPoint.new()
                    contact_point.system = 'phone'
                    contact_point.value = telephone_number
                    contact_point.use = 'work'
                    patient.telecom.push(contact_point)
                end
            end
        end
        entry = FHIR::Bundle::Entry.new()
        entry.resource = patient
        @bundle.entry.push(entry)
    end

    # Practitioner
    def generate_practitioner()
        practitioner = FHIR::Practitioner.new()

        orc_segment = @parser.get_parsed_segments('ORC')
        if orc_segment.nil? then
            return
        end
        
        orc_segment.first.select{|c| 
            Array[
                "Ordering Provider"
            ].include?(c['name'])
        }.each do |field|
            if ignore_fields?(field) then
                next
            end
            case field['name']
            when 'Ordering Provider' then
                # 依頼者
                field['array_data'].first.select{|c|
                    Array[
                        "ID Number",
                    ]
                }.each do |element|
                    case element['name']
                    when 'ID Number' then
                        # 医師ID
                        identifier = FHIR::Identifier.new()
                        identifier.system = "OID:1.2.392.100495.20.3.41#{get_facility_id}"
                        identifier.value = element['value']
                        practitioner.identifier = identifier
                    end
                end
                field['array_data'].each do |record|
                    # 医師氏名
                    practitioner.name.push(get_human_name(record))
                end
            end
        end
        entry = FHIR::Bundle::Entry.new()
        entry.resource = practitioner
        @bundle.entry.push(entry)
    end

    # PractitionerRole
    def generate_practitioner_role()
        practitioner_role = FHIR::PractitionerRole.new()

        orc_segment = @parser.get_parsed_segments('ORC')
        if orc_segment.nil? then
            return
        end
        
        orc_segment.first.select{|c| 
            Array[
                "Ordering Provider",
                "Entering Organization"
            ].include?(c['name'])
        }.each do |field|
            if ignore_fields?(field) then
                next
            end
            case field['name']
            when 'Ordering Provider' then
                # 依頼者
                field['array_data'].first.select{|c|
                    Array[
                        "ID Number",
                    ]
                }.each do |element|
                    case element['name']
                    when 'ID Number' then
                        # 医師ID
                        identifier = FHIR::Identifier.new()
                        identifier.system = "OID:1.2.392.100495.20.3.41#{get_facility_id}"
                        identifier.value = element['value']
                        practitioner_role.identifier = identifier
                    end
                end
            when 'Entering Organization' then
                # 入力組織
                practitioner_role.specialty.push(get_codeable_concept(field['array_data'].first))
            end
        end
        entry = FHIR::Bundle::Entry.new()
        entry.resource = practitioner_role
        @bundle.entry.push(entry)
    end
    
    # Organization
    def generate_organization()
        organization = FHIR::Organization.new()

        # 都道府県番号
        identifier = FHIR::Identifier.new()
        identifier.system = "OID:1.2.392.100495.20.3.21"
        identifier.value = @state_code
        organization.identifier.push(identifier)

        # 点数表番号
        identifier = FHIR::Identifier.new()
        identifier.system = "OID:1.2.392.100495.20.3.22"
        identifier.value = @fee_score_code
        organization.identifier.push(identifier)

        # 医療機関コード
        identifier = FHIR::Identifier.new()
        identifier.system = "OID:1.2.392.100495.20.3.23"
        identifier.value = @facility_code
        organization.identifier.push(identifier)

        orc_segment = @parser.get_parsed_segments('ORC')
        if orc_segment.nil? then
            return
        end
        
        orc_segment.first.select{|c| 
            Array[
                "Ordering Facility Name",
                "Ordering Facility Address",
                "Ordering Facility Phone Number",
            ].include?(c['name'])
        }.each do |field|
            if ignore_fields?(field) then
                next
            end
            case field['name']
            when 'Ordering Facility Name' then
                # 医療機関名称
                organization.name = field['value']
            when 'Ordering Facility Address' then
                # 医療機関所在地
                field['array_data'].each do |record|
                    organization.address.push(get_address(record))
                end                
            when 'Ordering Facility Phone Number' then
                # 医療機関電話番号
                telephone_number = get_telephone_number(field['array_data'].first)
                if !telephone_number.empty? then
                    contact_point = FHIR::ContactPoint.new()
                    contact_point.system = 'phone'
                    contact_point.value = telephone_number
                    organization.telecom.push(contact_point)
                end
            end
        end
        entry = FHIR::Bundle::Entry.new()
        entry.resource = organization
        @bundle.entry.push(entry)
    end

    # MedicationRequest
    def generate_medication_request()
        # ORC,RXE,TQ1,RXR を1つのグループにする
        segments_group = Array[]
        segments = Array[]
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
            @bundle.entry.push(entry)
        end
    end

    # Coverage
    def generate_coverage()
        in1_segment = @parser.get_parsed_segments('IN1')
        if in1_segment.nil? then
            return
        end
        
        in1_segment.each do |segment|
            coverage = FHIR::Coverage.new()
            segment.select{|c| 
                Array[
                    "Insurance Plan ID",
                    "Insurance Company ID",
                    "Insured’s Group Emp ID",
                    "Insured’s Group Emp Name",
                    "Insured’s Relationship To Patient",
                ].include?(c['name'])
            }.each do |field|
                if ignore_fields?(field) then
                    next
                end
                case field['name']
                when 'Insurance Plan ID' then
                    # 法制コード
                    field['array_data'].first.select{|c| 
                        Array[
                            "Identifier",
                        ].include?(c['name'])
                    }.each do |element|
                        case element['name']
                        when 'Identifier' then
                            insurance = get_insurance_code(element['value'])
                            if !insurance.nil? then
                                codeable_concept = FHIR::CodeableConcept.new()
                                coding = FHIR::Coding.new()            
                                coding.code = insurance[0]
                                coding.display = insurance[1]
                                coding.system = '1.2.392.100495.20.2.61'
                                codeable_concept.coding = coding
                                coverage.type = codeable_concept
                            end
                        end
                    end
                when 'Insurance Company ID' then
                    # 保険者番号 / 公費負担者番号
                    identifier = FHIR::Identifier.new()
                    if coverage.type.coding.code == '8' then
                        identifier.system = "OID:1.2.392.100495.20.3.71" # 公費負担者番号
                    else
                        identifier.system = "OID:1.2.392.100495.20.3.61" # 保険者番号
                    end
                    identifier.value = field['value']
                    coverage.identifier.push(identifier)
                when 'Insured’s Group Emp ID' then
                    # 記号
                    if coverage.type.coding.code == '8' then
                        break # 公費の場合は無視する
                    end
                    identifier = FHIR::Identifier.new()
                    identifier.system = "OID:1.2.392.100495.20.3.62"
                    identifier.value = field['value']
                    coverage.identifier.push(identifier)
                when 'Insured’s Group Emp Name' then
                    # 番号
                    if coverage.type.coding.code == '8' then
                        break # 公費の場合は無視する
                    end
                    identifier = FHIR::Identifier.new()
                    identifier.system = "OID:1.2.392.100495.20.3.63"
                    identifier.value = field['value']
                    coverage.identifier.push(identifier)
                when 'Insured’s Relationship To Patient' then
                    # 本人/家族
                    if coverage.type.coding.code == '8' then
                        break # 公費の場合は無視する
                    end
                    field['array_data'].first.select{|c| 
                        Array[
                            "Identifier",
                        ].include?(c['name'])
                    }.each do |element|
                        case element['name']
                        when 'Identifier' then
                            codeable_concept = FHIR::CodeableConcept.new()
                            coding = FHIR::Coding.new()            
                            coding.system = '1.2.392.100495.20.2.61'
                            case element['value']
                            when 'SEL', 'EME' then
                                coding.code = '1' # 被保険者
                                coding.display = '被保険者'            
                            when 'EXF', 'SPO', 'CHD' then
                                coding.code = '2' # 被扶養者
                                coding.display = '被扶養者'
                            end
                            codeable_concept.coding = coding
                            coverage.relationship = codeable_concept    
                        end
                    end
                end
            end
            entry = FHIR::Bundle::Entry.new()
            entry.resource = coverage
            @bundle.entry.push(entry)
        end
    end

    # HL7v2:CWE → FHIR:CodeableConcept
    def get_codeable_concept(record)
        codeable_concept = FHIR::CodeableConcept.new()
        coding = FHIR::Coding.new()
        record.select{|c| 
            Array[
                "Identifier",
                "Text",
                "Name of Coding System",
            ].include?(c['name'])
        }.each do |element|
            case element['name']
            when 'Identifier' then
                # 識別子
                coding.code = element['value']
            when 'Text' then
                # テキスト
                coding.display = element['value']
            when 'Name of Coding System' then
                # コードシステム名
                coding.system = element['value']
            end
        end
        codeable_concept.coding = coding
        return codeable_concept
    end

    # HL7v2:XPN,XCN → FHIR:HumanName
    def get_human_name(record)
        human_name = FHIR::HumanName.new()
        record.select{|c|
            Array[
                "Family Name",
                "Given Name",
                'Name Representation Code',
            ].include?(c['name'])
        }.each do |element|
            case element['name']
            when 'Family Name' then
                # 姓
                human_name.family = element['value']
            when 'Given Name' then
                # 名
                human_name.given = element['value']
            when 'Name Representation Code' then
                extension = FHIR::Extension.new()
                extension.url = "http://hl7.org/fhir/StructureDefinition/iso21090-EN-representation"
                extension.valueCode = 
                    case element['value']
                    when 'I' then 'IDE' # 漢字
                    when 'P' then 'SYL' # カナ
                    end
                human_name.extension.push(extension)
            end
        end
        return human_name
    end

    # HL7v2:XAD → FHIR:Address 変換
    def get_address(record)
        address = FHIR::Address.new()
        record.each do |element|
            case element['name']
            when 'Street Address', 'Other Geographic Designation' then
                # 住所
                address.line.push(element['value'])
            when 'City' then
                # 市区町村
                address.city = element['value']
            when 'State or Province' then
                # 都道府県
                address.state = element['value']
            when 'Country' then
                # 国
                address.country = element['value']
            when 'Zip or Postal Code' then
                # 郵便番号
                address.postalCode = element['value']
            end
        end
        return address
    end

    def get_telephone_number(record)
        telephone_number = ''
        record.select{|c|
            Array[
                "Telephone Number",
                "Unformatted Telephone number ",
            ].include?(c['name'])
        }.each do |element|
            case element['name']
            when 'Telephone Number' then
                telephone_number = element['value']
            when 'Unformatted Telephone number ' then
                telephone_number = element['value'] if telephone_number.empty?
            end
        end
        return telephone_number
    end

    def get_insurance_code(value)
        jhsd = @jahis_tables['JHSD0001'].find{|c| c['value'] == value}
        if jhsd.nil? then
            return nil
        end
        case jhsd['type']
        when 'MI' then # 医保
            case jhsd['value']
            when 'C0' then ['2','国保'] # 国保
            when '39' then ['7','後期高齢'] # 後期高齢
            else ['1','社保']  # 社保
            end
        when 'LI' then ['3','労災'] # 労災
        when 'TI' then ['4','自賠'] # 自賠
        when 'PS' then ['5','公害'] # 公害
        when 'OE' then ['6','自費'] # 自費
        when 'PE' then ['8','公費'] # 公費
        end
    end

    def get_facility_id()
        return "#{@state_code}#{@fee_score_code}#{@facility_code}"
    end

    def ignore_fields?(field)
        if Array['ST','TX','FT','NM','IS','ID','DT','TM','DTM','SI','GTS'].include?(field['type']) then
            return false
        else
            if field['array_data'].nil? || field['array_data'].empty? then
                return true 
            end
        end
        return false
    end
end

generator = FhirPrescriptionGenerator.new(get_message_example, generate: true)
puts generator.get_resource.to_json