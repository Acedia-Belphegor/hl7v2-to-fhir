require_relative 'generate_abstract'

class GenerateMessageHeader < GenerateAbstract
  def perform()
    msh_segment = get_segments('MSH')&.first
    return [] unless msh_segment.present?

    message_header = FHIR::MessageHeader.new
    message_header.id = SecureRandom.uuid

    trigger_event = msh_segment[:message_type].first[:trigger_event]
    table = get_hl7table("0003").find{|t|t["code"] == trigger_event}
    message_header.eventCoding = build_coding(table["code"], table["display"], 'http://terminology.hl7.org/CodeSystem/v2-0003')

    destination = FHIR::MessageHeader::Destination.new
    destination.name = msh_segment[:receiving_application].first[:namespace_id]
    message_header.destination << destination

    source = FHIR::MessageHeader::Source.new
    source.name = msh_segment[:sending_application].first[:namespace_id]
    message_header.source = source
    
    [build_entry(message_header)]
  end
end