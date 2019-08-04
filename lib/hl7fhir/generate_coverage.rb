# encoding: UTF-8
require_relative 'generate_abstract'

class GenerateCoverage < GenerateAbstract
    def perform()
        result = Array[]
        in1_segment = @parser.get_parsed_segments('IN1')
        if in1_segment.nil? then
            return
        end
        
        in1_segment.each do |segment|
            coverage = FHIR::Coverage.new()
            segment.select{|c| 
                Array[
                    "Insurance Plan ID",
                    "Insurance Company ID",
                    "Insured’s Group Emp ID",
                    "Insured’s Group Emp Name",
                    "Insured’s Relationship To Patient",
                ].include?(c['name'])
            }.each do |field|
                if ignore_fields?(field) then
                    next
                end
                case field['name']
                when 'Insurance Plan ID' then
                    # 法制コード
                    field['array_data'].first.select{|c| 
                        Array[
                            "Identifier",
                        ].include?(c['name'])
                    }.each do |element|
                        case element['name']
                        when 'Identifier' then
                            insurance = get_insurance_code(element['value'])
                            if !insurance.nil? then
                                codeable_concept = FHIR::CodeableConcept.new()
                                coding = FHIR::Coding.new()            
                                coding.code = insurance[0]
                                coding.display = insurance[1]
                                coding.system = '1.2.392.100495.20.2.61'
                                codeable_concept.coding = coding
                                coverage.type = codeable_concept
                            end
                        end
                    end
                when 'Insurance Company ID' then
                    # 保険者番号 / 公費負担者番号
                    identifier = FHIR::Identifier.new()
                    if coverage.type.coding.code == '8' then
                        identifier.system = "OID:1.2.392.100495.20.3.71" # 公費負担者番号
                    else
                        identifier.system = "OID:1.2.392.100495.20.3.61" # 保険者番号
                    end
                    identifier.value = field['value']
                    coverage.identifier.push(identifier)
                when 'Insured’s Group Emp ID' then
                    # 記号
                    if coverage.type.coding.code == '8' then
                        break # 公費の場合は無視する
                    end
                    identifier = FHIR::Identifier.new()
                    identifier.system = "OID:1.2.392.100495.20.3.62"
                    identifier.value = field['value']
                    coverage.identifier.push(identifier)
                when 'Insured’s Group Emp Name' then
                    # 番号
                    if coverage.type.coding.code == '8' then
                        break # 公費の場合は無視する
                    end
                    identifier = FHIR::Identifier.new()
                    identifier.system = "OID:1.2.392.100495.20.3.63"
                    identifier.value = field['value']
                    coverage.identifier.push(identifier)
                when 'Insured’s Relationship To Patient' then
                    # 本人/家族
                    if coverage.type.coding.code == '8' then
                        break # 公費の場合は無視する
                    end
                    field['array_data'].first.select{|c| 
                        Array[
                            "Identifier",
                        ].include?(c['name'])
                    }.each do |element|
                        case element['name']
                        when 'Identifier' then
                            codeable_concept = FHIR::CodeableConcept.new()
                            coding = FHIR::Coding.new()            
                            coding.system = '1.2.392.100495.20.2.61'
                            case element['value']
                            when 'SEL', 'EME' then
                                coding.code = '1' # 被保険者
                                coding.display = '被保険者'            
                            when 'EXF', 'SPO', 'CHD' then
                                coding.code = '2' # 被扶養者
                                coding.display = '被扶養者'
                            end
                            codeable_concept.coding = coding
                            coverage.relationship = codeable_concept    
                        end
                    end
                end
            end
            entry = FHIR::Bundle::Entry.new()
            entry.resource = coverage
            result.push(entry)
        end
        return result
    end
end