# encoding: UTF-8
require_relative 'generate_abstract'

class GenerateSpecimen < GenerateAbstract
    def perform()
        result = Array[]
        spm_segment = @parser.get_parsed_segments('SPM')
        if spm_segment.nil? then
            return
        end
        
        spm_segment.each do |segment|
            specimen = FHIR::Specimen.new()
            segment.select{|c| 
                Array[
                    "Set ID – SPM",
                    "Specimen ID ",
                    "Specimen Type",
                ].include?(c['name'])
            }.each do |field|
                if ignore_fields?(field) then
                    next
                end
                case field['name']
                when 'Set ID – SPM' then
                    # SPM-1.セットID-SPM
                    identifier = FHIR::Identifier.new()
                    identifier.system = 'SPM-1'
                    identifier.value = field['value']
                    specimen.identifier.push(identifier)
                when 'Specimen ID ' then
                    # SPM-2.検体ID
                    identifier = FHIR::Identifier.new()
                    identifier.system = 'SPM-2'
                    identifier.value = field['value']
                    specimen.identifier.push(identifier)
                when 'Specimen Type' then
                    # SPM-4.検体タイプ
                    specimen.type = get_codeable_concept(field['array_data'].first)
                end
            end
            entry = FHIR::Bundle::Entry.new()
            entry.resource = specimen
            result.push(entry)
        end
        return result
    end
end