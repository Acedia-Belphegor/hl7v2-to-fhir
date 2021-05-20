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

client = FHIR::Client.new("http://localhost:8080", default_format: 'json')
client.use_r4
FHIR::Model.client = client

device = FHIR::Device.new
device.id = SecureRandom.uuid

device.type = create_codeable_concept('01', '血圧計', 'PELICS')

device_name = FHIR::Device::DeviceName.new
device_name.name = "オムロン"
device_name.type = "manufacturer-name"
device.deviceName << device_name

puts device.to_json
