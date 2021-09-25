require 'json'
require 'fhir_client'
require 'securerandom'

class GenerateAbstract
  def initialize(params)        
    @message = params[:message]
    @bundle = params[:bundle]
    @params = params[:params]
  end

  def perform()
    raise NotImplementedError.new("You must implement #{self.class}##{__method__}")
  end

  def get_message()
    @message
  end

  def get_params()
    @params
  end

  def get_segments(id)
    @message.select{|segment|segment[:segment_id] == id}
  end

  def get_resource_from_id(id)
    @bundle.entry.find{|e|e.resource.id == id}&.resource
  end

  def get_resources_from_type(resource_type)
    @bundle.entry.select{|e|e.resource.resourceType == resource_type}.map{|e|e.resource}
  end

  def get_resources_from_identifier(resource_type, identifier)
    get_resources_from_type(resource_type).select{|r|r.identifier.include?(identifier)}
  end

  def get_medical_institution_code()
    "#{get_params[:prefecture_code]}#{get_params[:medical_fee_point_code]}#{get_params[:medical_institution_code]}"
  end

  def generate_identifier(value, system)
    identifier = FHIR::Identifier.new
    identifier.system = system
    identifier.value = value
    identifier
  end

  # HL7v2:XPN,XCN -> FHIR:HumanName
  def generate_human_name(name)
    return unless name.present?
    human_name = FHIR::HumanName.new
    human_name.use = :official
    human_name.family = name[:family_name][:surname]
    human_name.given << name[:given_name]
    human_name.text = "#{name[:family_name][:surname]}#{name[:given_name]}"

    extension = FHIR::Extension.new
    extension.url = "http://hl7.org/fhir/StructureDefinition/iso21090-EN-representation"
    extension.valueCode = case name[:name_representation_code]
                          when 'I' then :IDE # 漢字
                          when 'P' then :SYL # カナ
                          end
    human_name.extension << extension
    human_name
  end

  # HL7v2:XAD -> FHIR:Address 変換
  def generate_address(addr)
    return unless addr.present?
    address = FHIR::Address.new
    address.use = case addr[:address_type]
                  when 'H' then :home # 自宅
                  when 'B' then :work # 勤務先
                  when 'C' then :temp # 一時的な住所
                  end
    address.country = addr[:country]
    address.state = addr[:state_or_province]
    address.city = addr[:city]
    address.line << addr[:other_geographic_designation]
    address.text = addr[:street_address][:street_or_mailing_address] if addr[:street_address].present?
    address.postalCode = addr[:zip_or_postal_code]
    address
  end

  # HL7v2:XTN -> FHIR:ContactPoint 変換
  def generate_contact_point(telecom)
    return unless telecom.present?
    contact_point = FHIR::ContactPoint.new
    case telecom[:telecommunication_use_code]
    when 'PRN' # 主要な自宅番号
      contact_point.use = :home
    when 'WPN' # 勤務先番号
      contact_point.use = :work
    when 'NET' # ネットワーク(電子メール)アドレス
      contact_point.system = :email
    end
    case telecom[:telecommunication_equipment_type]
    when 'PH' # 電話
      contact_point.system = :phone
    when 'FX' # ファックス
      contact_point.system = :fax
    when 'CP' # 携帯電話
      contact_point.system = :phone
      contact_point.use = :mobile
    end
    contact_point.value = telecom[:telephone_number] || telecom[:unformatted_telephone_number_]
    contact_point
  end

  # HL7v2:CQ -> FHIR:Quantity 変換
  def generate_quantity(cq, system = nil)
    return unless cq.present?
    quantity = FHIR::Quantity.new
    quantity.value = cq[:quantity].to_numeric
    quantity.system = system
    if cq[:units].present?
      quantity.unit = cq[:units][:text]
      quantity.code = cq[:units][:identifier]
    end
    quantity
  end

  # HL7v2:CWE -> FHIR:CodeableConcept 変換
  def generate_codeable_concept(code)
    return unless code.present?
    codeable_concept = FHIR::CodeableConcept.new        
    if code[:identifier].present?
      codeable_concept.coding << build_coding(code[:identifier], code[:text], convert_coding_system(code[:name_of_coding_system]))
    end
    if code[:alternate_identifier].present?
      codeable_concept.coding << build_coding(code[:alternate_identifier], code[:alternate_text], convert_coding_system(code[:name_of_alternate_coding_system]))
    end
    codeable_concept
  end

  def convert_coding_system(coding_system)
    case coding_system
    when 'JAMISDP01' then 'urn:oid:1.2.392.100495.20.2.31' # JAMI標準用法コード
    when 'JHSP0003' then 'urn:oid:1.2.392.100495.20.2.34' # 投与方法
    when 'HL70162' then 'http://terminology.hl7.org/CodeSystem/v2-0162' # 投与経路
    when 'HL70164' then 'http://terminology.hl7.org/CodeSystem/v2-0164' # 投与装置
    when 'HL70069' then 'urn:oid:1.2.392.100495.20.2.51' # 診療部門
    when 'HL70482' then 'http://terminology.hl7.org/CodeSystem/v2-0482' # 入外区分
    when 'HL70550' then 'http://terminology.hl7.org/CodeSystem/v2-0550' # 身体部位
    when 'HL70495' then 'http://terminology.hl7.org/CodeSystem/v2-0495' # 身体部位修飾子
    when 'MR9P' then 'http://hl7fhir.jp/medication/MR9PCategory' # 処方区分
    when 'HOT','HOT9' then 'urn:oid:1.2.392.100495.20.2.74' # HOTコード
    else coding_system
    end
  end

  def get_hl7table(id)
    @hl7_tables ||= File.open(Pathname.new(File.dirname(File.expand_path(__FILE__))).join('json').join('HL7_TABLE.json')) do |io|
      JSON.load(io)
    end
    @hl7_tables[id]
  end

  def get_hl7table_from_code(id, code)
    get_hl7table(id).find{|t|t["code"] == code}
  end
end