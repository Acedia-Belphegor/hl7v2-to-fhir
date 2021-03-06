require_relative 'generate_abstract'

class GeneratePractitioner < GenerateAbstract
    def perform()
        orc_segment = get_segments('ORC')&.first
        return [] unless orc_segment.present?

        practitioner = FHIR::Practitioner.new
        practitioner.id = SecureRandom.uuid

        practitioner.identifier << generate_identifier(orc_segment[:ordering_provider].first[:id_number], 'urn:oid:1.2.392.100495.20.3.41.1')
        practitioner.name = orc_segment[:ordering_provider].map{|element|generate_human_name(element)}

        # RXE-13.オーダ発行者のDEA番号 (麻薬施用者の免許番号)
        dea_numbers = get_segments('RXE').map{|segment|segment[:ordering_providers_dea_number]}.reject(&:empty?)
        if dea_numbers.present?
            practitioner.qualification = dea_numbers.map{|dea_number|
                qualification = FHIR::Practitioner::Qualification.new
                qualification.identifier = generate_identifier(dea_number, 'urn:oid:1.2.392.100495.20.3.32')
                qualification
            }
        end

        entry = FHIR::Bundle::Entry.new
        entry.resource = practitioner
        [entry]
    end
end