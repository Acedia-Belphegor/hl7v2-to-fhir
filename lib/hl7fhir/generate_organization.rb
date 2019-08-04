# encoding: UTF-8
require_relative 'generate_abstract'

class GenerateOrganization < GenerateAbstract
    def perform()
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
        return Array[entry]
    end
end