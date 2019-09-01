require './lib/hl7fhir/fhir_prescription_generator'
require './lib/hl7v2/hl7example'

generator = FhirPrescriptionGenerator.new(get_example_rde, generate: true)
puts generator.get_resources.to_json