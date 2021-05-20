require 'fhir_client'

def create_codeable_concept(code, display, system = 'LC')
  codeable_concept = FHIR::CodeableConcept.new
  coding = FHIR::Coding.new
  coding.code = code
  coding.display = display
  coding.system = system
  codeable_concept.coding << coding
  codeable_concept
end

def create_quantity(value, unit = nil, code = nil)
  quantity = FHIR::Quantity.new
  quantity.value = value
  quantity.unit = unit
  quantity.code = code
  quantity
end

client = FHIR::Client.new("http://localhost:8080", default_format: 'json')
client.use_r4
FHIR::Model.client = client

observation = FHIR::Observation.new
observation.id = SecureRandom.uuid

observation.category << create_codeable_concept('vital-signs', 'バイタルサイン', 'http://terminology.hl7.org/CodeSystem/observation-category')
observation.code = create_codeable_concept('1101', '収縮期血圧', 'PELICS')
observation.valueQuantity = create_quantity(120, 'mmHg')
observation.bodySite = nil
observation.local_method = nil

reference = FHIR::Reference.new
reference.reference = "urn:uuid:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
observation.device = reference

observation.subject = nil
observation.performer = nil

puts observation.to_json
