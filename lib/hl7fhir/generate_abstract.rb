# encoding: UTF-8
require 'json'
require 'fhir_client'
require_relative '../hl7v2/hl7parser'

class GenerateAbstract
    def initialize(parser)
        @parser = parser
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
        if @jahis_tables.nil? then
            filename = Pathname.new(File.dirname(File.expand_path(__FILE__))).join('json').join('JAHIS_TABLES.json')
            @jahis_tables = File.open(filename) do |io|
                JSON.load(io)
            end
        end
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