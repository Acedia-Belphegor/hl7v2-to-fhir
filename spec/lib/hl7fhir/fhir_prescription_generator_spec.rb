RSpec.describe FhirPrescriptionGenerator do
    let(:generator) { FhirPrescriptionGenerator.new get_message_example('RDE'), generate: false }

    it '#perform' do
        generator.perform
        expect(generator.get_resources.entry.count).to eq 11
    end

    it 'generate patient' do
        generator.perform
        entry = generator.get_resources_from_type('Patient').first
        expect(entry.resource.name.first.family).to eq '患者'
        expect(entry.resource.name.first.given).to eq '太郎'
    end
end