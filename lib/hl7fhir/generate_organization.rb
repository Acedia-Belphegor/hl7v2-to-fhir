# encoding: UTF-8
require_relative 'generate_abstract'

class GenerateOrganization < GenerateAbstract
    def perform()
        organization = FHIR::Organization.new()
        organization.id = '0'

        # 都道府県番号
        identifier = FHIR::Identifier.new()
        identifier.system = "OID:1.2.392.100495.20.3.21"
        identifier.value = @parser.get_sending_facility[:state]
        organization.identifier.push(identifier)

        # 点数表番号
        identifier = FHIR::Identifier.new()
        identifier.system = "OID:1.2.392.100495.20.3.22"
        identifier.value = @parser.get_sending_facility[:point]
        organization.identifier.push(identifier)

        # 医療機関コード
        identifier = FHIR::Identifier.new()
        identifier.system = "OID:1.2.392.100495.20.3.23"
        identifier.value = @parser.get_sending_facility[:facility]
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
                # ORC-21.オーダ施設名
                organization.name = field['value']
            when 'Ordering Facility Address' then
                # ORC-22.オーダ施設住所
                field['array_data'].each do |record|
                    organization.address.push(generate_address(record))
                end                
            when 'Ordering Facility Phone Number' then
                # ORC-23.オーダ施設電話番号
                field['array_data'].each do |record|
                    organization.telecom.push(generate_contact_point(record))
                end
            end
        end
        entry = FHIR::Bundle::Entry.new()
        entry.resource = organization
        return Array[entry]
    end
end