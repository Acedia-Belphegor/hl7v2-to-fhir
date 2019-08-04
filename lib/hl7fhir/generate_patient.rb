# encoding: UTF-8
require_relative 'generate_abstract'

class GeneratePatient < GenerateAbstract
    def perform()
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
        return Array[entry]
    end
end