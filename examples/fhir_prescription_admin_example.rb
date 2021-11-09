require 'fhir_client'

def build_codeable_concept(code, display, system = 'LC')
  codeable_concept = FHIR::CodeableConcept.new
  coding = FHIR::Coding.new
  coding.code = code
  coding.display = display
  coding.system = system
  codeable_concept.coding << coding
  codeable_concept
end

def build_quantity(value, unit = nil, code = nil, system = nil)
  quantity = FHIR::Quantity.new
  quantity.value = value
  quantity.unit = unit
  quantity.code = code
  quantity.system = system
  quantity
end

def build_identifier(value, system)
  identifier = FHIR::Identifier.new
  identifier.system = system
  identifier.value = value
  identifier
end

def build_entry(resource)
  entry = FHIR::Bundle::Entry.new
  entry.resource = resource
#   entry.fullUrl = "urn:uuid:#{resource.id}"
  entry
end

client = FHIR::Client.new("http://localhost:8080", default_format: 'json')
client.use_r4
FHIR::Model.client = client

bundle = FHIR::Bundle.new
# bundle.id = SecureRandom.uuid

### ムコダイン錠２５０ｍｇ
medication_administration = FHIR::MedicationAdministration.new
# medication_administration.id = SecureRandom.uuid
medication_administration.status = :completed
medication_administration.category = build_codeable_concept('I', '入院オーダ', 'http://terminology.hl7.org/CodeSystem/v2-0482')

medication_administration.identifier << build_identifier('12345678', 'http://www.example.com/fhir/order-number')
medication_administration.identifier << build_identifier('1', 'urn:oid:1.2.392.100495.20.3.81')
medication_administration.identifier << build_identifier('1', 'urn:oid:1.2.392.100495.20.3.82')

medication_administration.medicationCodeableConcept = build_codeable_concept('103835401', 'ムコダイン錠２５０ｍｇ', 'urn:oid:1.2.392.100495.20.2.74')

reference = FHIR::Reference.new
reference.reference = "Patient/1"
medication_administration.subject = reference

medication_administration.effectiveDateTime = DateTime.new(2016, 8, 25, 8, 30, 0, "+09:00")

performer = FHIR::MedicationAdministration::Performer.new
performer.function = build_codeable_concept('performer', 'Performer', 'http://hl7.org/fhir/ValueSet/med-admin-perform-function')
reference = FHIR::Reference.new
reference.reference = "Practitioner/1"
reference.display = "看護師 夏子"
performer.actor = reference
medication_administration.performer = performer

reference = FHIR::Reference.new
reference.reference = "MedicationRequest/1"
medication_administration.request = reference

dosage = FHIR::MedicationAdministration::Dosage.new
dosage.route = build_codeable_concept('0', '経口', 'urn:oid:1.2.392.200250.2.2.20.40')
dosage.local_method = build_codeable_concept('1', '内服', 'urn:oid:1.2.392.200250.2.2.20.30')
dosage.dose = build_quantity(1, '錠', 'TAB', 'urn:oid:1.2.392.100495.20.2.101')

medication_administration.dosage = dosage

extension = FHIR::Extension.new
extension.url = "http://hl7fhir.jp/fhir/StructureDefinition/JP_MedicationAdminstrationRequestDepartment"
extension.valueCodeableConcept = build_codeable_concept('01', '内科', 'http://terminology.hl7.org/CodeSystem/v2-0069')
medication_administration.extension << extension

extension = FHIR::Extension.new
extension.url = "http://hl7fhir.jp/fhir/StructureDefinition/JP_MedicationAdministrationRequester"
reference = FHIR::Reference.new
reference.reference = "Practitioner/2"
reference.display = "医師 春子"
extension.valueReference = reference
medication_administration.extension << extension

extension = FHIR::Extension.new
extension.url = "http://hl7fhir.jp/fhir/StructureDefinition/JP_MedicationAdministrationRequestAuthoredOn"
extension.valueDateTime = DateTime.new(2016, 8, 25, 0, 0, 0, "+09:00")
medication_administration.extension << extension

extension = FHIR::Extension.new
extension.url = "http://hl7fhir.jp/fhir/StructureDefinition/JP_MedicationAdminstrationLocation"
reference = FHIR::Reference.new
reference.reference = "Location/1"
reference.display = "09A病棟 021病室 4ベッド"
extension.valueReference = reference
medication_administration.extension << extension

bundle.entry = []
bundle.entry << build_entry(medication_administration)


### パンスポリンＴ錠１００ １００ｍｇ
medication_administration = FHIR::MedicationAdministration.new
# medication_administration.id = SecureRandom.uuid
medication_administration.status = :stopped
medication_administration.category = build_codeable_concept('I', '入院オーダ', 'http://terminology.hl7.org/CodeSystem/v2-0482')

medication_administration.identifier << build_identifier('12345678', 'http://www.example.com/fhir/order-number')
medication_administration.identifier << build_identifier('1', 'urn:oid:1.2.392.100495.20.3.81')
medication_administration.identifier << build_identifier('2', 'urn:oid:1.2.392.100495.20.3.82')

medication_administration.medicationCodeableConcept = build_codeable_concept('110626901', 'パンスポリンＴ錠１００ １００ｍｇ', 'urn:oid:1.2.392.100495.20.2.74')

reference = FHIR::Reference.new
reference.reference = "Patient/1"
medication_administration.subject = reference

medication_administration.effectiveDateTime = DateTime.new(2016, 8, 25, 8, 30, 0, "+09:00")

reference = FHIR::Reference.new
reference.reference = "MedicationRequest/2"
medication_administration.request = reference

extension = FHIR::Extension.new
extension.url = "http://hl7fhir.jp/fhir/StructureDefinition/JP_MedicationAdminstrationRequestDepartment"
extension.valueCodeableConcept = build_codeable_concept('01', '内科', 'http://terminology.hl7.org/CodeSystem/v2-0069')
medication_administration.extension << extension

extension = FHIR::Extension.new
extension.url = "http://hl7fhir.jp/fhir/StructureDefinition/JP_MedicationAdministrationRequester"
reference = FHIR::Reference.new
reference.reference = "Practitioner/2"
reference.display = "医師 春子"
extension.valueReference = reference
medication_administration.extension << extension

extension = FHIR::Extension.new
extension.url = "http://hl7fhir.jp/fhir/StructureDefinition/JP_MedicationAdministrationRequestAuthoredOn"
extension.valueDateTime = DateTime.new(2016, 8, 25, 0, 0, 0, "+09:00")
medication_administration.extension << extension

bundle.entry << build_entry(medication_administration)


puts bundle.to_json
