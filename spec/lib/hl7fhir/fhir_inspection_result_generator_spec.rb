RSpec.describe FhirInspectionResultGenerator do
    let(:generator) { FhirInspectionResultGenerator.new get_message, generate: false }

    def get_message()
        return <<~MSG
            MSH|^~\&|DOCX|HIS|GW|GW|20111024181046.736||OUL^R22^OUL_R22|20111024000001|P|2.5||||||~ISO IR87||ISO 2022-1994
            PID|0001||1014360||駿河^葵^^^^^L^I~スルガ^アオイ^^^^^L^P||19520717|F|||^^^^422-8033^JPN^H^静岡県静岡市登呂２９４−１３||^PRN^PH^^^^^^^^^054-000-0000|||||||||||||||||||20030205115729
            PV1|0001|O|2^^^^^C||||ishi01^テスト^医師^^^^^^^L^^^^^I|||002
            SPM|0001|||023^血清^JC10^01^血清^99XYZ
            ORC|SC|000000002928810|||||||20111024000000|ishi01^テスト^医師^^^^^^^L^^^^^I||ishi01^テスト^医師^^^^^^^L^^^^^I|2^^^^^C||||002^内科^99XY1|Fu^^99XY2|||追手町病院|^^^^422-0000^JPN^^静岡市駿河区追手町1-1|^^^^^^^^^^^054-252-1400||||||O^外来患者^HL70482
            OBR|0001|000000002928810|000000002928810|1^生化学^99XYZ|||20111024|20111024||||||||ishi01^テスト^医師^^^^^^^L^^^^^I||||||20111024160328
            OBX|0005|NM|3B035000002327201^GOT(AST)^JC10^10207^GOT(AST)^99LAB||14|IU/L^IU/L^99UNT|8-38||||F|||20111024000000
            OBX|0006|NM|3B045000002327201^GPT(ALT)^JC10^10208^GPT(ALT)^99LAB||9|IU/L^IU/L^99UNT|4-43||||F|||20111024000000
            OBX|0008|NM|3B070000002327101^ＡＬＰ^JC10^10209^ＡＬＰ^99LAB||147|IU/L^IU/L^99UNT|110-354||||F|||20111024000000
            OBX|0007|NM|3B050000002327201^ＬＤＨ^JC10^10206^ＬＤＨ^99LAB||139|IU/L^IU/L^99UNT|121-245||||F|||20111024000000
            OBX|0004|NM|3J010000002327101^Ｔ−Ｂｉｌ^JC10^10213^Ｔ−Ｂｉｌ^99LAB||0.7|mg/dl^mg/dl^99UNT|0.2-1.2||||F|||20111024000000
            OBX|0010|NM|3C025000002327201^Ｕｒｅａ−Ｎ^JC10^10215^Ｕｒｅａ−Ｎ^99LAB||12|mg/dl^mg/dl^99UNT|8-22||||F|||20111024000000
            OBX|0011|NM|3C015000002327101^Ｃｒｅ^JC10^10216^Ｃｒｅ^99LAB||0.53|mg/dl^mg/dl^99UNT|0.47-0.79||||F|||20111024000000
            OBX|0009|NM|3F050000002327101^Ｔ−ＣＨＯ^JC10^10201^Ｔ−ＣＨＯ^99LAB||175|mg/dl^mg/dl^99UNT|120-220||||F|||20111024000000
            OBX|0016|NM|3H030000002327101^Ｃａ^JC10^10218^Ｃａ^99LAB||8.5|mg/dl^mg/dl^99UNT|8.0-10.2||||F|||20111024000000
            OBX|0018|NM|5C070000002306201^ＣＲＰ^JC10^10221^ＣＲＰ^99LAB||2.0|mg/dl^mg/dl^99UNT|0.0-0.5||||F|||20111024000000
            OBX|0001|NM|3A010000002327101^ＴＰ^JC10^10222^ＴＰ^99LAB||5.8|g/dl^g/dl^99UNT|6.5-8.2||||F|||20111024000000
            OBX|0013|NM|3H010000002326101^Ｎａ^JC10^10240^Ｎａ^99LAB||140|mEq/L^mEq/L^99UNT|130-148||||F|||20111024000000
            OBX|0015|NM|3H015000002326101^Ｋ^JC10^10241^Ｋ^99LAB||4.0|mEq/L^mEq/L^99UNT|3.6-5.0||||F|||20111024000000
            OBX|0014|NM|3H020000002326101^Ｃｌ^JC10^10242^Ｃｌ^99LAB||104|mEq/L^mEq/L^99UNT|98-110||||F|||20111024000000
            SPM|0002|||019^血液^JC10^02^血液^99XYZ
            ORC|SC|000000002928810|||||||20111024000000|ishi01^テスト^医師^^^^^^^L^^^^^I||ishi01^テスト^医師^^^^^^^L^^^^^I|2^^^^^C||||002^内科^99XY1|Fu^^99XY2|||追手町病院|^^^^422-0000^JPN^^静岡市駿河区追手町1-1|^^^^^^^^^^^054-252-1400||||||O^外来患者^HL70482
            OBR|0001|000000002928810|000000002928810|3^血液^99XYZ|||20111024|20111024||||||||ishi01^テスト^医師^^^^^^^L^^^^^I||||||20111024160328
            OBX|0002|NM|2A020000001930101^ＲＢＣ^JC10^30004^ＲＢＣ^99LAB||397|*10＾4/ul^*10＾4/ul^99UNT|376-500||||F|||20111024000000
            OBX|0003|NM|2A030000001928201^ＨＧＢ^JC10^30005^ＨＧＢ^99LAB||12.8|g/dl^g/dl^99UNT|11.3-15.2|L|||F|||20111024000000
            OBX|0001|NM|2A010000001930101^ＷＢＣ^JC10^30002^ＷＢＣ^99LAB||7.1|*10＾3/ul^*10＾3/ul^99UNT|3.5-9.5||||F|||20111024000000
            OBX|0001|NM|2A040000001930202^ＨＴ^JC10^30006^ＨＴ^99LAB||37.9|%^%^99UNT|33.0-45.0||||F|||20111024000000
            OBX|0005|NM|2A060000001930102^ＭＣＶ^JC10^30007^ＭＣＶ^99LAB||95.3|nm＾3^nm＾3^99UNT|79-100||||F|||20111024000000
            OBX|0006|NM|2A070000001930102^ＭＣＨ^JC10^30008^ＭＣＨ^99LAB||32.2|pg^pg^99UNT|27-34||||F|||20111024000000
            OBX|0007|NM|2A080000001930102^ＭＣＨＣ^JC10^30009^ＭＣＨＣ^99LAB||33.7|%^%^99UNT|30-35||||F|||20111024000000
        MSG
    end

    it '#perform' do
        generator.perform
        # expect(generator.get_resources.entry.count).to eq 28
        expect(generator.get_resources.entry.count).to eq 7
    end
end