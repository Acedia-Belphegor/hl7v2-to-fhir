# encoding: UTF-8
require_relative 'generate_abstract'

class GenerateSpecimen < GenerateAbstract
    def perform()
        # SPM,OBR を1つのグループにする
        segments_group = Array[]
        segments = Array[]
        result = Array[]
        @parser.get_parsed_message().select{|c| 
            Array['SPM','OBR'].include?(c[0]['value'])
        }.each do |segment|
            if segment[0]['value'] == 'SPM' then
                segments_group.push(segments) if !segments.empty?
                segments = Array[]
            end
            segments.push(segment)
        end
        segments_group.push(segments) if !segments.empty?
        
        segments_group.each do |segments|
            specimen = FHIR::Specimen.new()
            segments.each do |segment|
                case segment[0]['value']
                when 'SPM' then
                    segment.select{|c| 
                        Array[
                            "Set ID – SPM",
                            "Specimen ID ",
                            "Specimen Type",
                            "Specimen Collection Date/Time",
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
                        when 'Specimen Collection Date/Time' then
                            # SPM-17.検体採取日時
                            date_time = parse_str_datetime(field['value'])
                            if !date_time.nil? then
                                collection = FHIR::Specimen::Collection.new()
                                collection.collectedDateTime = date_time
                                specimen.collection = collection
                            end
                        end
                    end
                when 'OBR' then
                    segment.select{|c| 
                        Array[
                            "Universal Service Identifier",
                            "Observation Date/Time #",
                        ].include?(c['name'])
                    }.each do |field|
                        if ignore_fields?(field) then
                            next
                        end
                        case field['name']
                        when 'Universal Service Identifier' then
                            # OBR-4.検査項目ID
                            processing = FHIR::Specimen::Processing.new()
                            processing.procedure = get_codeable_concept(field['array_data'].first)
                            specimen.processing = processing
                        when 'Observation Date/Time #' then
                            # OBR-7.検査/採取日時
                            date_time = parse_str_datetime(field['value'])
                            if !date_time.nil? then
                                collection = FHIR::Specimen::Collection.new()
                                collection.collectedDateTime = date_time
                                specimen.collection = collection
                            end
                        end
                    end
                end
            end
            entry = FHIR::Bundle::Entry.new()
            entry.resource = specimen
            result.push(entry)        
        end
        return result
    end
end