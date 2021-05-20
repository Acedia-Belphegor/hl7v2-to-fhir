require_relative 'fhir_abstract_generator'

class FhirInjectionGenerator < FhirAbstractGenerator
  def perform()
    @bundle.entry.concat(GenerateMessageHeader.new(get_params).perform) # MessageHeader
    @bundle.entry.concat(GeneratePatient.new(get_params).perform) # Patient
    @bundle.entry.concat(GenerateOrganization.new(get_params).perform) # Organization
    @bundle.entry.concat(GeneratePractitioner.new(get_params).perform) # Practitioner
    @bundle.entry.concat(GeneratePractitionerRole.new(get_params).perform) # PractitionerRole
    @bundle.entry.concat(GenerateCoverage.new(get_params).perform) # Coverage
    @bundle.entry.concat(GenerateMedicationRequestInjection.new(get_params).perform) # MedicationRequest
    @bundle.entry.concat(GenerateAllergyIntolerance.new(get_params).perform) # AllergyIntolerance
    self
  end

  private
  def validation()
    message = get_params[:message]

    # 必須セグメントチェック
    results = %w[MSH PID ORC RXE TQ1 RXR].map{|s|{segment: s, existed: s.in?(message.map{|f|f[:segment_id]})}}&.select{|r|!r[:existed]}
    if results.present?
      return { code: "segment_error", message: "Required segment does not exist (#{results.map{|r|r[:segment]}.join(",")})" }
    end

    msh_segment = message.select{|s|s[:segment_id] == "MSH"}&.first

    # MSH-9
    message_type = msh_segment[:message_type]&.first
    if message_type.present?
      # RDE^O11 以外は許容しない
      unless message_type[:message_code] == "RDE" && message_type[:trigger_event] == "O11"
        return { code: "field_error", message: "[MSH-9.MessageType] invalid values (#{message_type.values.join("^")})" }
      end
    else
      return { code: "field_error", message: "[MSH-9.MessageType] is null" }
    end

    nil
  end
end