require_relative 'fhir_abstract_generator'

class FhirInspectionResultGenerator < FhirAbstractGenerator
  def perform()
    @bundle.entry.concat(GenerateMessageHeader.new(get_params).perform) # MessageHeader
    @bundle.entry.concat(GeneratePatient.new(get_params).perform) # Patient
    @bundle.entry.concat(GenerateOrganization.new(get_params).perform) # Organization
    @bundle.entry.concat(GeneratePractitioner.new(get_params).perform) # Practitioner
    @bundle.entry.concat(GeneratePractitionerRole.new(get_params).perform) # PractitionerRole
    @bundle.entry.concat(GenerateSpecimenObservation.new(get_params).perform) # Specimen/Observation
    self
  end

  private
  def validation()
    nil
  end
end