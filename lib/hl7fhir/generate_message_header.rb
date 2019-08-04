# encoding: UTF-8
require_relative 'generate_abstract'

class GenerateMessageHeader < GenerateAbstract
    def perform()
        message_header = FHIR::MessageHeader.new()

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
                # 送信アプリケーション
                source = FHIR::MessageHeader::Source.new()
                source.name = field['value']
                message_header.source = source
            when 'Sending Facility' then
                # 送信施設
                sending_facility = field['value']
                if sending_facility.length == 10 then
                    @state_code = sending_facility[0,2] # 都道府県番号
                    @fee_score_code = sending_facility[2,1] # 点数表番号
                    @facility_code = sending_facility[3,7] # 医療機関コード
                end
            when 'Receiving Application' then
                # 受信アプリケーション
                destination = FHIR::MessageHeader::Destination.new()
                destination.name = field['value']
                message_header.destination = destination
            when 'Message Type' then
                # メッセージ型
                coding = FHIR::Coding.new()
                coding.code = field['value']
                coding.system = 'http://www.hl7.org'
                message_header.eventCoding = coding
            end
        end
        entry = FHIR::Bundle::Entry.new()
        entry.resource = message_header
        return Array[entry]
    end
end