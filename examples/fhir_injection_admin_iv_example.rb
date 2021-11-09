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

medication_administration = FHIR::MedicationAdministration.new
# medication_administration.id = SecureRandom.uuid
medication_administration.status = :completed
medication_administration.category = build_codeable_concept('I', '入院オーダ', 'http://terminology.hl7.org/CodeSystem/v2-0482')

medication_administration.identifier << build_identifier('123456789012345', 'http://www.example.com/fhir/order-number')
medication_administration.identifier << build_identifier('1', 'urn:oid:1.2.392.100495.20.3.81')
medication_administration.identifier << build_identifier('1', 'urn:oid:1.2.392.100495.20.3.82')

medication = FHIR::Medication.new
# medication.id = SecureRandom.uuid
medication.id = "1"

# ソリタ－Ｔ３号輸液５００ｍＬ
ingredient = FHIR::Medication::Ingredient.new
ingredient.itemCodeableConcept = build_codeable_concept('100558502', 'ホリゾン注射液１０ｍｇ', 'urn:oid:1.2.392.100495.20.2.74')

ratio = FHIR::Ratio.new
ratio.numerator = build_quantity(1, 'アンプル', 'AMP', 'urn:oid:1.2.392.100495.20.2.101')
ratio.denominator = build_quantity(1, '回', 'KAI', 'urn:oid:1.2.392.100495.20.2.101')
ingredient.strength = ratio

medication.ingredient << ingredient
medication_administration.contained << medication

reference = FHIR::Reference.new
reference.reference = "Medication/1"
medication_administration.medicationReference = reference

reference = FHIR::Reference.new
reference.reference = "Patient/1"
medication_administration.subject = reference

period = FHIR::Period.new
period.start = DateTime.new(2016, 7, 1, 10, 5, 21, "+09:00")
period.end = DateTime.new(2016, 7, 1, 10, 5, 21, "+09:00")
medication_administration.effectivePeriod = period

performer = FHIR::MedicationAdministration::Performer.new
performer.function = build_codeable_concept('performer', 'Performer', 'http://hl7.org/fhir/ValueSet/med-admin-perform-function')
reference = FHIR::Reference.new
reference.reference = "Practitioner/1"
reference.display = "看護 花子"
performer.actor = reference
medication_administration.performer = performer

reference = FHIR::Reference.new
reference.reference = "MedicationRequest/1"
medication_administration.request = reference

dosage = FHIR::MedicationAdministration::Dosage.new

body_structure = FHIR::BodyStructure.new
body_structure.id = "1"
body_structure.location = build_codeable_concept('ARM', '腕', 'http://terminology.hl7.org/CodeSystem/v2-0550')
body_structure.locationQualifier << build_codeable_concept('R', '右', 'http://terminology.hl7.org/CodeSystem/v2-0495')

extension = FHIR::Extension.new
extension.url = "http://hl7.org/fhir/StructureDefinition/bodySite"
reference = FHIR::Reference.new
reference.reference = "BodyStructure/1"
reference.display = "右腕"
extension.valueReference = reference

site = FHIR::CodeableConcept.new
site.extension << extension

extension = FHIR::Extension.new
extension.url = "http://hl7.org/fhir/StructureDefinition/JP_MedicationAdminstrationSiteComment"
extension.valueString = "左利きのため"
site.extension << extension

dosage.site = site
medication_administration.contained << body_structure

dosage.route = build_codeable_concept('IV', '静脈内', 'http://terminology.hl7.org/CodeSystem/v2-0162')
dosage.local_method = build_codeable_concept('101', '静注(末梢)', 'http://hl7fhir.jp/99ILL')

extension = FHIR::Extension.new
extension.url = "http://hl7.org/fhir/StructureDefinition/JP_MedicationAdminstrationMethodComment"
extension.valueString = "１分ほどかけて緩徐に行いました"
dosage.local_method.extension << extension

extension = FHIR::Extension.new
extension.url = "http://hl7.org/fhir/StructureDefinition/JP_MedicationAdminstrationDosageComment"
extension.valueString = "痙攣が発生したため、主治医に確認の上実施しました"
dosage.extension << extension

medication_administration.dosage = dosage

device = FHIR::Device.new
device.id = "1"
device.type = build_codeable_concept('01', 'シリンジ', 'http://hl7fhir.jp/medication/99ILL')
reference = FHIR::Reference.new
reference.reference = "Device/1"
reference.display = "シリンジ"
medication_administration.device << reference
medication_administration.contained << device

extension = FHIR::Extension.new
extension.url = "http://hl7fhir.jp/fhir/StructureDefinition/JP_MedicationAdminstrationRequestDepartment"
extension.valueCodeableConcept = build_codeable_concept('01', '内科', 'http://terminology.hl7.org/CodeSystem/v2-0069')
medication_administration.extension << extension

extension = FHIR::Extension.new
extension.url = "http://hl7fhir.jp/fhir/StructureDefinition/JP_MedicationAdministrationRequester"
reference = FHIR::Reference.new
reference.reference = "Practitioner/2"
reference.display = "医師 一郎"
extension.valueReference = reference
medication_administration.extension << extension

extension = FHIR::Extension.new
extension.url = "http://hl7fhir.jp/fhir/StructureDefinition/JP_MedicationAdministrationRequestAuthoredOn"
extension.valueDateTime = DateTime.new(2016, 7, 1, 0, 0, 0, "+09:00")
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

puts bundle.to_json
