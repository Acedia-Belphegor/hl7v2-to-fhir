# encoding: UTF-8
require_relative 'generate_abstract'

class GenerateSpecimen < GenerateAbstract
    def perform()
        results = []        
        get_segments_group.each do |segments|
            specimen = FHIR::Specimen.new
            specimen.id = results.length
            segments.each do |segment|
                case segment[0]['value']
                when 'SPM'
                    segment.select{|c| 
                        [
                            "Set ID – SPM",
                            "Specimen ID ",
                            "Specimen Type",
                            "Specimen Collection Date/Time",
                        ].include?(c['name'])
                    }.each do |field|
                        next if ignore_fields?(field)
                        case field['name']
                        when 'Set ID – SPM'
                            # SPM-1.セットID-SPM
                            identifier = FHIR::Identifier.new
                            identifier.system = 'SPM-1'
                            identifier.value = field['value']
                            specimen.identifier << identifier
                        when 'Specimen ID '
                            # SPM-2.検体ID
                            identifier = FHIR::Identifier.new
                            identifier.system = 'SPM-2'
                            identifier.value = field['value']
                            specimen.identifier << identifier
                        when 'Specimen Type'
                            # SPM-4.検体タイプ
                            specimen.type = generate_codeable_concept(field['array_data'].first)
                        when 'Specimen Collection Date/Time'
                            # SPM-17.検体採取日時
                            date_time = parse_str_datetime(field['value'])
                            if date_time.present?
                                collection = FHIR::Specimen::Collection.new
                                collection.collectedDateTime = date_time
                                specimen.collection = collection
                            end
                        end
                    end
                when 'OBR'
                    segment.select{ |c| ["Universal Service Identifier","Observation Date/Time #"].include?(c['name']) }.each do |field|
                        next if ignore_fields?(field)
                        case field['name']
                        when 'Universal Service Identifier'
                            # OBR-4.検査項目ID
                            processing = FHIR::Specimen::Processing.new
                            processing.procedure = generate_codeable_concept(field['array_data'].first)
                            specimen.processing = processing
                        when 'Observation Date/Time #'
                            # OBR-7.検査/採取日時
                            date_time = parse_str_datetime(field['value'])
                            if date_time.present?
                                collection = FHIR::Specimen::Collection.new
                                collection.collectedDateTime = date_time
                                specimen.collection = collection
                            end
                        end
                    end
                end
            end
            # 患者の参照
            get_resources_from_type('Patient').each do |entry|
                specimen.subject = create_reference(entry)
            end
            entry = FHIR::Bundle::Entry.new
            entry.resource = specimen
            results << entry
        end
        results
    end

    def get_segments_group()
        segments_group = []
        segments = []

        message_type = @parser.get_parsed_fields('MSH','Message Type').first
        segment_ids = 
            case message_type['array_data'].first.select{|c| c['name'] == 'Message Structure'}.first['value']
            when 'OUL_R22' then ['SPM','OBR']
            when 'ORU_R01' then ['OBR']
            else []
            end

        # SPM,OBRを1つのグループにまとめて配列を生成する
        @parser.get_parsed_message().select{ |c| segment_ids.include?(c[0]['value']) }.each do |segment|
            if segment[0]['value'] == segment_ids.first
                segments_group << segments if segments.present?
                segments = []
            end
            segments << segment
        end
        segments_group << segments if segments.present?
    end
end