require './lib/hl7fhir/fhir_injection_generator'
require './lib/hl7v2/hl7example'

generator = FhirInjectionGenerator.new(get_example_rde_injection, generate: true)
puts generator.get_resources.to_json