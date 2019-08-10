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
                # PID-3.患者IDリスト
                identifier = FHIR::Identifier.new()
                identifier.system = "OID:1.2.392.100495.20.3.51.1#{@parser.get_sending_facility[:all]}"
                identifier.value = field['array_data'].first.find{|c| c['name'] == 'ID Number'}['value']
                patient.identifier = identifier
            when 'Patient Name' then
                # PID-5.患者氏名
                field['array_data'].each do |record|
                    human_name = get_human_name(record)
                    human_name.use = 'official'
                    patient.name.push(human_name)
                end
            when 'Date/Time of Birth' then
                # PID-7.生年月日
                patient.birthDate = Date.parse(field['value'])
            when 'Administrative Sex' then
                # PID-8.性別
                patient.gender = 
                    case field['value']
                    when 'M' then 'male'   # 男性
                    when 'F' then 'female' # 女性
                    end
            when 'Patient Address' then
                # PID-11.患者の住所
                field['array_data'].each do |record|
                    patient.address.push(get_address(record))
                end
            when 'Phone Number - Home' then
                # PID-13.電話番号-自宅
                field['array_data'].each do |record|
                    patient.telecom.push(get_contact_point(record))
                end
            when 'Phone Number - Business' then
                # PID-14.電話番号-勤務先
                field['array_data'].each do |record|
                    patient.telecom.push(get_contact_point(record))
                end
            end
        end
        entry = FHIR::Bundle::Entry.new()
        entry.resource = patient
        return Array[entry]
    end
end