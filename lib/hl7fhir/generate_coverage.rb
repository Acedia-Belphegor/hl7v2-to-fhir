# encoding: UTF-8
require_relative 'generate_abstract'

class GenerateCoverage < GenerateAbstract
    def perform()
        results = []
        @parser.get_parsed_segments('IN1').each do |segment|
            coverage = FHIR::Coverage.new
            coverage.id = results.length.to_s
            segment.select{|c| 
                [
                    "Insurance Plan ID",
                    "Insurance Company ID",
                    "Insured’s Group Emp ID",
                    "Insured’s Group Emp Name",
                    "Plan Effective Date",
                    "Plan Expiration Date",
                    "Insured’s Relationship To Patient",
                ].include?(c['name'])
            }.each do |field|
                next if ignore_fields?(field)
                case field['name']
                when 'Insurance Plan ID'
                    # IN1-2.保険プランID(法制コード)
                    field['array_data'].first.select{ |c| ["Identifier"].include?(c['name']) }.each do |element|
                        case element['name']
                        when 'Identifier'
                            insurance = generate_insurance_code(element['value'])
                            unless insurance.nil?
                                coverage.type = create_codeable_concept(insurance[0],insurance[1],'1.2.392.100495.20.2.61')
                            end
                        end
                    end
                when 'Insurance Company ID'
                    # IN1-3.保険会社ID(保険者番号 / 公費負担者番号)
                    identifier = FHIR::Identifier.new
                    if coverage.type.coding.first.code == '8'
                        identifier.system = "OID:1.2.392.100495.20.3.71" # 公費負担者番号
                    else
                        identifier.system = "OID:1.2.392.100495.20.3.61" # 保険者番号
                    end
                    identifier.value = field['value']
                    coverage.identifier << identifier
                when 'Insured’s Group Emp ID'
                    # IN1-10.被保険者グループ雇用者ID(記号)
                    if coverage.type.coding.first.code == '8'
                        next # 公費の場合は無視する
                    end
                    identifier = FHIR::Identifier.new
                    identifier.system = "OID:1.2.392.100495.20.3.62"
                    identifier.value = field['value']
                    coverage.identifier << identifier
                when 'Insured’s Group Emp Name'
                    # IN1-11.被保険者グループ雇用者名(番号)
                    next if coverage.type.coding.first.code == '8' # 公費の場合は無視する
                    identifier = FHIR::Identifier.new
                    identifier.system = "OID:1.2.392.100495.20.3.63"
                    identifier.value = field['value']
                    coverage.identifier << identifier
                when 'Plan Effective Date'
                    # IN1-12.プラン有効日付(有効開始日)
                    unless field['value'].empty?
                        coverage.period.nil? ? period = FHIR::Period.new : period = coverage.period
                        period.start = parse_str_datetime(field['value'])
                    end
                when 'Plan Expiration Date'
                    # IN1-13.プラン失効日付(有効終了日)
                    unless field['value'].empty?
                        coverage.period.nil? ? period = FHIR::Period.new : period = coverage.period
                        period.end = parse_str_datetime(field['value'])
                    end
                when 'Insured’s Relationship To Patient'
                    # IN1-17.被保険者と患者の関係(本人/家族)
                    next if coverage.type.coding.first.code == '8' # 公費の場合は無視する
                    field['array_data'].first.select{ |c| ["Identifier"].include?(c['name']) }.each do |element|
                        case element['name']
                        when 'Identifier'
                            codeable_concept = FHIR::CodeableConcept.new
                            coding = FHIR::Coding.new            
                            coding.system = '1.2.392.100495.20.2.61'
                            case element['value']
                            when 'SEL', 'EME'
                                coding.code = '1' # 被保険者
                                coding.display = '被保険者'            
                            when 'EXF', 'SPO', 'CHD'
                                coding.code = '2' # 被扶養者
                                coding.display = '被扶養者'
                            end
                            codeable_concept.coding << coding
                            coverage.relationship = codeable_concept    
                        end
                    end
                end
            end
            # 受益者の参照
            get_resources_from_type('Patient').each do |entry|
                coverage.beneficiary = create_reference(entry)
            end
            # 支払者の参照
            reference = FHIR::Reference.new
            reference.type = 'Organization'
            reference.id = 'dummy'
            coverage.payor = [reference]
            entry = FHIR::Bundle::Entry.new
            entry.resource = coverage
            results << entry
        end
        results
    end
end