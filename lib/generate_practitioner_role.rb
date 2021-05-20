require_relative 'generate_abstract'

class GeneratePractitionerRole < GenerateAbstract
  def perform()
    practitioner_role = FHIR::PractitionerRole.new
    practitioner_role.id = SecureRandom.uuid

    orc_segment = get_segments('ORC')&.first
    return [] unless orc_segment.present?

    practitioner_role.code << create_codeable_concept('doctor','Doctor','http://terminology.hl7.org/CodeSystem/practitioner-role') # 医師
    practitioner_role.practitioner = create_reference(get_resources_from_type('Practitioner').first)
    practitioner_role.organization = create_reference(get_resources_from_type('Organization').first)

    entry = FHIR::Bundle::Entry.new
    entry.resource = practitioner_role
    [entry]
  end
end