# encoding: UTF-8
require_relative 'generate_abstract'

class GeneratePatient < GenerateAbstract
    def perform()
        patient = FHIR::Patient.new
        patient.id = SecureRandom.uuid

        pid_segment = @parser.get_parsed_segments('PID')
        return if pid_segment.nil?
        
        pid_segment.first.select{|c|
            [
                "Patient Identifier List",
                "Patient Name",
                "Date/Time of Birth",
                "Administrative Sex",
                "Patient Address",
                "Phone Number - Home",
                "Phone Number - Business",
                "Primary Language",
                "Marital Status",
                "Multiple Birth Indicator",
                "Birth Order",
                "Patient Death Date and Time",
                "Patient Death Indicator",
            ].include?(c['name'])
        }.each do |field|
            next if ignore_fields?(field)
            case field['name']
            when 'Patient Identifier List'
                # PID-3.患者IDリスト
                identifier = FHIR::Identifier.new
                identifier.system = "urn:oid:1.2.392.100495.20.3.51.1#{@parser.get_sending_facility[:all]}"
                identifier.value = field['array_data'].first.find{|c| c['name'] == 'ID Number'}['value']
                patient.identifier << identifier
            when 'Patient Name'
                # PID-5.患者氏名
                field['array_data'].each do |record|
                    human_name = generate_human_name(record)
                    human_name.use = :official
                    patient.name << human_name
                end
            when 'Date/Time of Birth'
                # PID-7.生年月日
                patient.birthDate = Date.parse(field['value'])
            when 'Administrative Sex'
                # PID-8.性別
                patient.gender = 
                    case field['value']
                    when 'M' then :male   # 男性
                    when 'F' then :female # 女性
                    end
            when 'Patient Address'
                # PID-11.患者の住所
                field['array_data'].each do |record|
                    patient.address << generate_address(record)
                end
            when 'Phone Number - Home'
                # PID-13.電話番号-自宅
                field['array_data'].each do |record|
                    patient.telecom << generate_contact_point(record)
                end
            when 'Phone Number - Business'
                # PID-14.電話番号-勤務先
                field['array_data'].each do |record|
                    patient.telecom << generate_contact_point(record)
                end
            when 'Primary Language'
                # PID-15.使用言語
                communication = FHIR::Communication.new
                communication.language = generate_codeable_concept(field['value']) 
                patient.communication = communication
            when 'Marital Status'
                # PID-16.婚姻状況
                patient.maritalStatus = generate_codeable_concept(field['value'])
            when 'Multiple Birth Indicator'
                # PID-24.多胎児識別情報
                if field['value'].present?
                    field['value'] == 'Y' ? patient.multipleBirthBoolean = true : patient.multipleBirthBoolean = false
                end
            when 'Birth Order'
                # PID-25.誕生順序
                patient.multipleBirthInteger = field['value'].to_i if field['value'].present?
            when 'Patient Death Date and Time'
                # PID-29.患者死亡日時
                patient.deceasedDateTime = DateTime.parse(field['value']) if field['value'].present?
            when 'Patient Death Indicator'
                # PID-30.患者死亡識別情報
                if field['value'].present?
                    field['value'] == 'Y' ? patient.deceasedBoolean = true : patient.deceasedBoolean = false
                end
            end
        end
        entry = FHIR::Bundle::Entry.new
        entry.resource = patient
        [entry]
    end
end