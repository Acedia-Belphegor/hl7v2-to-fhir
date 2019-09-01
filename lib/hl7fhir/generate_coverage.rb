# encoding: UTF-8
require_relative 'generate_abstract'

class GenerateCoverage < GenerateAbstract
    def perform()
        result = Array[]
        @parser.get_parsed_segments('IN1').each do |segment|
            coverage = FHIR::Coverage.new()
            coverage.id = result.length
            segment.select{|c| 
                Array[
                    "Insurance Plan ID",
                    "Insurance Company ID",
                    "Insured’s Group Emp ID",
                    "Insured’s Group Emp Name",
                    "Plan Effective Date",
                    "Plan Expiration Date",
                    "Insured’s Relationship To Patient",
                ].include?(c['name'])
            }.each do |field|
                if ignore_fields?(field) then
                    next
                end
                case field['name']
                when 'Insurance Plan ID' then
                    # IN1-2.保険プランID(法制コード)
                    field['array_data'].first.select{|c| 
                        Array[
                            "Identifier",
                        ].include?(c['name'])
                    }.each do |element|
                        case element['name']
                        when 'Identifier' then
                            insurance = get_insurance_code(element['value'])
                            if !insurance.nil? then
                                coverage.type = create_codeable_concept(insurance[0],insurance[1],'1.2.392.100495.20.2.61')
                            end
                        end
                    end
                when 'Insurance Company ID' then
                    # IN1-3.保険会社ID(保険者番号 / 公費負担者番号)
                    identifier = FHIR::Identifier.new()
                    if coverage.type.coding.code == '8' then
                        identifier.system = "OID:1.2.392.100495.20.3.71" # 公費負担者番号
                    else
                        identifier.system = "OID:1.2.392.100495.20.3.61" # 保険者番号
                    end
                    identifier.value = field['value']
                    coverage.identifier.push(identifier)
                when 'Insured’s Group Emp ID' then
                    # IN1-10.被保険者グループ雇用者ID(記号)
                    if coverage.type.coding.code == '8' then
                        next # 公費の場合は無視する
                    end
                    identifier = FHIR::Identifier.new()
                    identifier.system = "OID:1.2.392.100495.20.3.62"
                    identifier.value = field['value']
                    coverage.identifier.push(identifier)
                when 'Insured’s Group Emp Name' then
                    # IN1-11.被保険者グループ雇用者名(番号)
                    if coverage.type.coding.code == '8' then
                        next # 公費の場合は無視する
                    end
                    identifier = FHIR::Identifier.new()
                    identifier.system = "OID:1.2.392.100495.20.3.63"
                    identifier.value = field['value']
                    coverage.identifier.push(identifier)
                when 'Plan Effective Date' then
                    # IN1-13.プラン有効日付(有効開始日)
                    if !field['value'].empty? then
                        if coverage.period.nil? then
                            period = FHIR::Period.new()
                        else
                            period = coverage.period
                        end
                        period.start = parse_str_datetime(field['value'])    
                    end
                when 'Plan Expiration Date' then
                    # IN1-14.プラン失効日付(有効終了日)
                    if !field['value'].empty? then
                        if coverage.period.nil? then
                            period = FHIR::Period.new()
                        else
                            period = coverage.period
                        end
                        period.end = parse_str_datetime(field['value'])
                    end
                when 'Insured’s Relationship To Patient' then
                    # IN1-17.被保険者と患者の関係(本人/家族)
                    if coverage.type.coding.code == '8' then
                        next # 公費の場合は無視する
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