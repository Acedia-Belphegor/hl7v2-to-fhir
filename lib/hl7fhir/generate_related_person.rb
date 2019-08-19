# encoding: UTF-8
require_relative 'generate_abstract'

class GenerateRelatedPerson < GenerateAbstract
    def perform()
        result = Array[]
        @parser.get_parsed_segments('NK1').each do |segment|
            related_person = FHIR::RelatedPerson.new()
            segment.select{|c| 
                Array[
                    "Name",
                    "Relationship",
                    "Address",
                    "Phone Number",
                    "Business Phone Number",
                ].include?(c['name'])
            }.each do |field|
                if ignore_fields?(field) then
                    next
                end
                case field['name']
                when 'Name' then
                    # NK1-2.氏名
                    field['array_data'].each do |record|
                        human_name = get_human_name(record)
                        human_name.use = 'official'
                        related_person.name.push(human_name)
                    end
                when 'Relationship' then
                    # NK1-3.続柄
                    related_person.relationship = get_codeable_concept(field['array_data'].first)
                when 'Address' then
                    # NK1-4.住所
                    field['array_data'].each do |record|
                        related_person.address.push(get_address(record))
                    end
                when 'Phone Number' then
                    # NK1-5.電話番号
                    field['array_data'].each do |record|
                        related_person.telecom.push(get_contact_point(record))
                    end
                when 'Business Phone Number' then
                    # NK1-6.勤務先電話番号
                    field['array_data'].each do |record|
                        related_person.telecom.push(get_contact_point(record))
                    end
                end
            end
            # 患者
            patient = get_resources_from_type('Patient')
            if !patient.empty? then
                reference = FHIR::Reference.new()
                reference.type = patient.first.resource.resourceType
                reference.identifier = patient.first.resource.identifier
                related_person.patient = reference
            end
            entry = FHIR::Bundle::Entry.new()
            entry.resource = related_person
            result.push(entry)
        end
        return result
    end
end