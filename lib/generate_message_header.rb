require_relative 'generate_abstract'

class GenerateMessageHeader < GenerateAbstract
    def perform()
        message_header = FHIR::MessageHeader.new
        message_header.id = SecureRandom.uuid



        
        entry = FHIR::Bundle::Entry.new
        entry.resource = message_header
        [entry]
    end
end