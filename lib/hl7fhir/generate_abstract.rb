# encoding: UTF-8
require 'json'
require 'fhir_client'
require_relative '../hl7v2/hl7parser'

class GenerateAbstract
    def initialize(params)        
        @parser = params[:parser]
        @bundle = params[:bundle]
    end

    def perform()
        raise NotImplementedError.new("You must implement #{self.class}##{__method__}")
    end

    def get_resources_from_type(resource_type)
        @bundle.entry.select{ |c| c.resource.resourceType == resource_type }
    end

    def get_resources_from_identifier(resource_type, identifier)
        get_resources_from_type(resource_type).select{ |c| c.resource.identifier == identifier }
    end

    # HL7v2:CWE -> FHIR:CodeableConcept
    def generate_codeable_concept(record)
        codeable_concept = FHIR::CodeableConcept.new
        coding = FHIR::Coding.new
        record.select{ |c| ["Identifier","Text","Name of Coding System"].include?(c['name']) }.each do |element|
            case element['name']
            when 'Identifier'
                # CWE-1.識別子
                coding.code = element['value']
            when 'Text'
                # CWE-2.テキスト
                coding.display = element['value']
            when 'Name of Coding System'
                # CWE-3.コードシステム名
                coding.system = element['value']
            end
        end
        codeable_concept.coding << coding
        codeable_concept
    end

    # HL7v2:XPN,XCN -> FHIR:HumanName
    def generate_human_name(record)
        human_name = FHIR::HumanName.new
        record.select{ |c| ["Family Name","Given Name",'Name Representation Code'].include?(c['name']) }.each do |element|
            case element['name']
            when 'Family Name'
                # XPN-1,XCN-2.姓
                human_name.family = element['value']
            when 'Given Name'
                # XPN-2,XCN-3.名
                human_name.given << element['value']
            when 'Name Representation Code'
                # XPN-8,XCN-15.名前表記コード
                extension = FHIR::Extension.new
                extension.url = "http://hl7.org/fhir/StructureDefinition/iso21090-EN-representation"
                extension.valueCode = 
                    case element['value']
                    when 'I' then 'IDE' # 漢字
                    when 'P' then 'SYL' # カナ
                    end
                human_name.extension << extension
            end
        end
        human_name
    end

    # HL7v2:XAD -> FHIR:Address 変換
    def generate_address(record)
        address = FHIR::Address.new
        record.each do |element|
            case element['name']
            when 'Street Address', 'Other Geographic Designation'
                # XAD-1.通りの住所 / XAD-8.その他の地理表示
                address.line << element['value']
            when 'City'
                # XAD-3.市区町村
                address.city = element['value']
            when 'State or Province'
                # XAD-4.都道府県
                address.state = element['value']
            when 'Country'
                # XAD-6.国
                address.country = element['value']
            when 'Zip or Postal Code'
                # XAD-5.郵便番号
                address.postalCode = element['value']
            end
        end
        address
    end

    # HL7v2:CQ -> FHIR:Quantity 変換
    def generate_quantity(record)
        quantity = FHIR::Quantity.new
        record.each do |element|
            case element['name']
            when 'Quantity'
                # CQ-1.数量
                quantity.value = element['value'].to_i
            when 'Units'
                # CQ-2.単位付複合数量
                if element['array_data'].present?
                    codeable_concept = generate_codeable_concept(element['array_data'])
                    quantity.code = codeable_concept.coding.first.code
                    quantity.unit = codeable_concept.coding.first.display
                end
            end
        end
        quantity
    end

    # HL7v2:XTN -> FHIR:ContactPoint 変換
    def generate_contact_point(record)
        contact_point = FHIR::ContactPoint.new
        record.select{|c|
            [
                "Telephone Number",
                "Telecommunication Use Code",
                "Telecommunication Equipment Type",
                "Email Address",
                "Unformatted Telephone number ",
            ].include?(c['name'])
        }.each do |element|
            case element['name']
            when 'Telephone Number','Unformatted Telephone number '
                # XTN-1.電話番号 / XTN-12.非定型の電話番号
                contact_point.value = element['value'] if contact_point.value.nil? && !element['value'].empty?
            when 'Telecommunication Use Code'
                # XTN-2.テレコミュニケーション用途コード
                case element['value']
                when 'PRN' # 主要な自宅番号
                    contact_point.use = 'home'
                when 'WPN' # 勤務先番号
                    contact_point.use = 'work'
                when 'NET' # ネットワーク(電子メール)アドレス
                    contact_point.system = 'email'
                end
            when 'Telecommunication Equipment Type'
                # XTN-3.テレコミュニケーション装置型
                case element['value']
                when 'PH' # 電話
                    contact_point.system = 'phone'
                when 'FX' # ファックス
                    contact_point.system = 'fax'
                when 'CP' # 携帯電話
                    contact_point.system = 'phone'
                    contact_point.use = 'mobile'
                end
            when 'Email Address'
                # XTN-4.電子メールアドレス
                contact_point.value = element['value'] if contact_point.system == 'email'
            end
        end
        contact_point
    end

    # HL7v2:XCN -> FHIR:Identifier
    def generate_identifier_from_xcn(record)
        identifier = FHIR::Identifier.new
        record.select{ |c| ["ID Number"] }.each do |element|
            case element['name']
            when 'ID Number'
                identifier.system = "OID:1.2.392.100495.20.3.41.1#{@parser.get_sending_facility[:all]}"
                identifier.value = element['value']                
            end
        end
        identifier
    end

    # JHSD表:0001(保険種別) -> 電子処方箋CDA:1.2.392.100495.20.2.61(保険種別コード) 変換
    def generate_insurance_code(value)
        if @jahis_tables.nil?
            filename = Pathname.new(File.dirname(File.expand_path(__FILE__))).join('json').join('JAHIS_TABLES.json')
            @jahis_tables = File.open(filename) do |io|
                JSON.load(io)
            end
        end
        jhsd = @jahis_tables['JHSD0001'].find{|c| c['value'] == value}
        return nil if jhsd.nil?

        case jhsd['type']
        when 'MI' # 医保
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

    # MERIT-9(MR9P):剤形略号 -> 電子処方箋CDA:1.2.392.100495.20.2.21(剤形区分コード) 変換
    def generate_medication_category(record)
        codeable_concept = generate_codeable_concept(record)
        coding = FHIR::Coding.new
        coding.system = 'OID:1.2.392.100495.20.2.21'
        case codeable_concept.coding.code
        when 'TAB','CAP','PWD','SYR' # TAB:錠剤 / CAP:カプセル剤 / PWD:散剤,ドライシロップ剤 / SYR:シロップ剤
            coding.code = '1'
            coding.display = '内服'
        when 'SUP','LQD','OIT','CRM','TPE' # SUP:坐剤 / LQD:液剤 / OIT:軟膏,ゲル / CRM:クリーム / TPE:テープ,貼付剤
            coding.code = '3'
            coding.display = '外用'
        when 'INJ' # INJ:注射剤
            coding.code = '5'
            coding.display = '注射'
        else
            coding.code = '9'
            coding.display = 'その他'
            codeable_concept.text = codeable_concept.coding.displey
        end
        codeable_concept.coding << coding
        codeable_concept
    end

    def create_codeable_concept(code, display, system = 'LC')
        codeable_concept = FHIR::CodeableConcept.new
        coding = FHIR::Coding.new
        coding.code = code
        coding.display = display
        coding.system = system
        codeable_concept.coding << coding
        codeable_concept
    end

    def create_reference(entry)
        reference = FHIR::Reference.new
        reference.type = entry.resource.resourceType
        reference.id = entry.resource.id
        reference
    end

    def create_reference_from_resource(resource)
        reference = FHIR::Reference.new
        reference.type = resource.resourceType
        reference.id = resource.id
        reference
    end    
    
    def ignore_fields?(field)
        if ['*','ST','TX','FT','NM','IS','ID','DT','TM','DTM','SI','GTS'].include?(field['type'])
            return false # 単一データ型のフィールドのため無視しない
        else
            if field['array_data'].nil? || field['array_data'].empty?
                return true # 複数データ型のフィールドで配列(パースデータ)が存在しない場合は無視する
            end
        end
        false # 無視しない
    end

    def parse_str_datetime(str_datetime)
        begin
            DateTime.parse(str_datetime)
        rescue => e
            nil
        end
    end
end