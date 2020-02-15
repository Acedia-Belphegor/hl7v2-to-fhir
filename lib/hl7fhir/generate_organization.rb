# encoding: UTF-8
require_relative 'generate_abstract'

class GenerateOrganization < GenerateAbstract
    def perform()
        organization = FHIR::Organization.new
        organization.id = SecureRandom.uuid

        # 都道府県番号
        identifier = FHIR::Identifier.new
        identifier.system = "OID:1.2.392.100495.20.3.21"
        identifier.value = @parser.get_sending_facility[:state]
        organization.identifier << identifier

        # 点数表番号
        identifier = FHIR::Identifier.new
        identifier.system = "OID:1.2.392.100495.20.3.22"
        identifier.value = @parser.get_sending_facility[:point]
        organization.identifier << identifier

        # 医療機関コード
        identifier = FHIR::Identifier.new
        identifier.system = "OID:1.2.392.100495.20.3.23"
        identifier.value = @parser.get_sending_facility[:facility]
        organization.identifier << identifier

        orc_segment = @parser.get_parsed_segments('ORC')
        return if orc_segment.nil?
        
        orc_segment.first.select{|c| 
            [
                "Ordering Facility Name",
                "Ordering Facility Address",
                "Ordering Facility Phone Number",
            ].include?(c['name'])
        }.each do |field|
            next if ignore_fields?(field)
            case field['name']
            when 'Ordering Facility Name'
                # ORC-21.オーダ施設名
                organization.name = field['value']
            when 'Ordering Facility Address'
                # ORC-22.オーダ施設住所
                field['array_data'].each do |record|
                    organization.address << generate_address(record)
                end                
            when 'Ordering Facility Phone Number'
                # ORC-23.オーダ施設電話番号
                field['array_data'].each do |record|
                    organization.telecom << generate_contact_point(record)
                end
            end
        end
        entry = FHIR::Bundle::Entry.new
        entry.resource = organization
        [entry]
    end
end