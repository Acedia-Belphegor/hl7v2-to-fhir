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

def create_identifier(value, system)
    identifier = FHIR::Identifier.new
    identifier.system = system
    identifier.value = value
    identifier
end

client = FHIR::Client.new("http://localhost:8080", default_format: 'json')
client.use_r4
FHIR::Model.client = client

medication_administration = FHIR::MedicationAdministration.new
medication_administration.id = SecureRandom.uuid
medication_administration.status = :completed
medication_administration.category = create_codeable_concept('inpatient', 'Inpatient', 'http://hl7.org/fhir/ValueSet/medication-admin-category')

medication_administration.identifier << create_identifier('123456789012345', 'http://hl7.org/fhir/CodeSystem/OrderNumber')
medication_administration.identifier << create_identifier('01', 'http://hl7.org/fhir/CodeSystem/RpNumber')
medication_administration.identifier << create_identifier('001', 'http://hl7.org/fhir/CodeSystem/RpSubNumber')

medication = FHIR::Medication.new
medication.id = SecureRandom.uuid

ingredient = FHIR::Medication::Ingredient.new
ingredient.itemCodeableConcept = create_codeable_concept('107750602', 'ソリタ－Ｔ３号輸液５００ｍＬ', 'urn:oid:1.2.392.100495.20.2.74')

extension = FHIR::Extension.new
extension.url = "http://hl7fhir.jp/fhir/StructureDefinition/Extension-JPCore-ComponentAmount"
extension.valueQuantity = create_quantity(1, '本', 'HON')
ingredient.extension << extension

extension = FHIR::Extension.new
extension.url = "http://hl7fhir.jp/fhir/StructureDefinition/Extension-JPCore-LotNumber"
extension.valueString = '1234'
ingredient.extension << extension

medication.ingredient << ingredient

ingredient = FHIR::Medication::Ingredient.new
ingredient.itemCodeableConcept = create_codeable_concept('108010001', 'アドナ注（静脈用）５０ｍｇ', 'urn:oid:1.2.392.100495.20.2.74')

extension = FHIR::Extension.new
extension.url = "http://hl7fhir.jp/fhir/StructureDefinition/Extension-JPCore-ComponentAmount"
extension.valueQuantity = create_quantity(1, 'アンプル', 'AMP')
ingredient.extension << extension

extension = FHIR::Extension.new
extension.url = "http://hl7fhir.jp/fhir/StructureDefinition/Extension-JPCore-LotNumber"
extension.valueString = '5678'
ingredient.extension << extension

medication.ingredient << ingredient

medication_administration.contained << medication

reference = FHIR::Reference.new
reference.reference = "urn:uuid:#{medication.id}"
medication_administration.medicationReference = reference

reference = FHIR::Reference.new
reference.reference = "urn:uuid:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
medication_administration.subject = reference

period = FHIR::Period.new
period.start = DateTime.new(2021, 1, 1, 9, 0, 0, "+09:00")
period.end = DateTime.new(2021, 1, 1, 12, 0, 0, "+09:00")
medication_administration.effectivePeriod = period

performer = FHIR::MedicationAdministration::Performer.new
performer.function = create_codeable_concept('performer', 'Performer', 'http://hl7.org/fhir/ValueSet/med-admin-perform-function')
reference = FHIR::Reference.new
reference.reference = "urn:uuid:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
performer.actor = reference
medication_administration.performer = performer

medication_administration.reasonCode << create_codeable_concept('b', 'Given as Ordered', 'http://hl7.org/fhir/ValueSet/reason-medication-given-codes')

reference = FHIR::Reference.new
reference.reference = "urn:uuid:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
medication_administration.request = reference

reference = FHIR::Reference.new
reference.reference = "urn:uuid:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
medication_administration.device = reference

dosage = FHIR::MedicationAdministration::Dosage.new
dosage.site = create_codeable_concept('ARM', '腕', 'http://hl7fhir.jp/HL70550')
dosage.route = create_codeable_concept('IV', '静脈内', 'http://hl7fhir.jp/HL70162')
dosage.local_method = create_codeable_concept('102', '点滴静注(末梢)', 'http://hl7fhir.jp/99ILL')
dosage.dose = create_quantity(510, 'ml')
dosage.text = '左手に実施'

ratio = FHIR::Ratio.new
ratio.numerator = create_quantity(510, 'ml')
ratio.denominator = create_quantity(1, 'h')
dosage.rateRatio = ratio

medication_administration.dosage = dosage

result = medication_administration.to_json
puts result
