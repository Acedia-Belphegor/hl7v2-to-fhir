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

def build_quantity(value, unit = nil, code = nil)
    quantity = FHIR::Quantity.new
    quantity.value = value
    quantity.unit = unit
    quantity.code = code
    quantity
end

def build_identifier(value, system)
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
medication_administration.category = build_codeable_concept('inpatient', 'Inpatient', 'http://hl7.org/fhir/ValueSet/medication-admin-category')

medication_administration.identifier << build_identifier('123456789012345', 'http://hl7.org/fhir/CodeSystem/OrderNumber')
medication_administration.identifier << build_identifier('01', 'http://hl7.org/fhir/CodeSystem/RpNumber')
medication_administration.identifier << build_identifier('001', 'http://hl7.org/fhir/CodeSystem/RpSubNumber')

medication = FHIR::Medication.new
medication.id = SecureRandom.uuid

item = FHIR::Medication.new
item.id = SecureRandom.uuid
item.code = build_codeable_concept('107750602', 'ソリタ－Ｔ３号輸液５００ｍＬ', 'urn:oid:1.2.392.100495.20.2.74')
ratio = FHIR::Ratio.new
ratio.numerator = build_quantity(500, 'ml')
ratio.denominator = build_quantity(1, '本')
item.amount = ratio
batch = FHIR::Medication::Batch.new
batch.lotNumber = '1234'
batch.expirationDate = Date.new(2021, 3, 31)
item.batch = batch

ingredient = FHIR::Medication::Ingredient.new
reference = FHIR::Reference.new
reference.reference = "urn:uuid:#{item.id}"
ingredient.itemReference = reference
medication.ingredient << ingredient
medication.contained << item

item = FHIR::Medication.new
item.id = SecureRandom.uuid
item.code = build_codeable_concept('108010001', 'アドナ注（静脈用）５０ｍｇ', 'urn:oid:1.2.392.100495.20.2.74')
ratio = FHIR::Ratio.new
ratio.numerator = build_quantity(10, 'ml')
ratio.denominator = build_quantity(1, 'アンプル')
item.amount = ratio
batch = FHIR::Medication::Batch.new
batch.lotNumber = '5678'
batch.expirationDate = Date.new(2021, 3, 31)
item.batch = batch

ingredient = FHIR::Medication::Ingredient.new
reference = FHIR::Reference.new
reference.reference = "urn:uuid:#{item.id}"
ingredient.itemReference = reference
medication.ingredient << ingredient
medication.contained << item

batch = FHIR::Medication::Batch.new
batch.lotNumber = ''
batch.expirationDate = Date.new(2021, 3, 31)
medication.batch = batch

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
performer.function = build_codeable_concept('performer', 'Performer', 'http://hl7.org/fhir/ValueSet/med-admin-perform-function')
reference = FHIR::Reference.new
reference.reference = "urn:uuid:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
performer.actor = reference
medication_administration.performer = performer

medication_administration.reasonCode << build_codeable_concept('b', 'Given as Ordered', 'http://hl7.org/fhir/ValueSet/reason-medication-given-codes')

reference = FHIR::Reference.new
reference.reference = "urn:uuid:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
medication_administration.request = reference

reference = FHIR::Reference.new
reference.reference = "urn:uuid:xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
medication_administration.device = reference

dosage = FHIR::MedicationAdministration::Dosage.new
dosage.site = build_codeable_concept('ARM', '腕', 'http://hl7fhir.jp/HL70550')
dosage.route = build_codeable_concept('IV', '静脈内', 'http://hl7fhir.jp/HL70162')
dosage.local_method = build_codeable_concept('102', '点滴静注(末梢)', 'http://hl7fhir.jp/99ILL')
dosage.dose = build_quantity(510, 'ml')
dosage.text = '左手に実施'

ratio = FHIR::Ratio.new
ratio.numerator = build_quantity(510, 'ml')
ratio.denominator = build_quantity(1, 'h')
dosage.rateRatio = ratio

medication_administration.dosage = dosage

result = medication_administration.to_json
puts result
