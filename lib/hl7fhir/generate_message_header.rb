# encoding: UTF-8
require_relative 'generate_abstract'

class GenerateMessageHeader < GenerateAbstract
    def perform()
        message_header = FHIR::MessageHeader.new()
        message_header.id = '0'

        msh_segment = @parser.get_parsed_segments('MSH')
        if msh_segment.nil? then
            return
        end

        msh_segment.first.select{|c|
            Array[
                "Sending Application",
                "Sending Facility",
                "Receiving Application",
                "Message Type",
            ].include?(c['name'])
        }.each do |field|
            case field['name']
            when 'Sending Application' then
                # MSH-3.送信アプリケーション
                source = FHIR::MessageHeader::Source.new()
                source.name = field['value']
                message_header.source = source
            when 'Sending Facility' then
                # MSH-4.送信施設
                sending_facility = field['value']
            when 'Receiving Application' then
                # MSH-5.受信アプリケーション
                destination = FHIR::MessageHeader::Destination.new()
                destination.name = field['value']
                message_header.destination.push(destination)
            when 'Message Type' then
                # MSH-9.メッセージ型
                coding = FHIR::Coding.new()
                coding.code = field['value']
                coding.system = 'http://www.hl7fhir.jp'
                message_header.eventCoding = coding
            end
        end
        entry = FHIR::Bundle::Entry.new()
        entry.resource = message_header
        return Array[entry]
    end
end