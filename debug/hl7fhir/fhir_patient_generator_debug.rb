require './lib/hl7fhir/fhir_patient_generator'
require './lib/hl7v2/hl7example'

generator = FhirPatientGenerator.new(get_example_adt, generate: true)
puts generator.get_resources.to_json