require './lib/hl7fhir/fhir_inspection_result_generator'
require './lib/hl7v2/hl7example'

generator = FhirInspectionResultGenerator.new(get_example_oul, generate: true)
puts generator.get_resources.to_json