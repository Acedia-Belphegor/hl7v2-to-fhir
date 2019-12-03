RSpec.describe FhirInjectionGenerator do
    let(:generator) { FhirInjectionGenerator.new get_message, generate: false }

    def get_message()
        return <<~MSG
            MSH|^~\&|HL7v2|1319999999|HL7FHIR|1319999999|20160821161523||RDE^O11^RDE_O11|201608211615230143|P|2.5||||||~ISOIR87||ISO 2022-1994
            PID|||1000000001^^^^PI||患者^太郎^^^^^L^I~カンジャ^タロウ^^^^^L^P||19791101|M|||^^渋谷区^東京都^1510071^JPN^H^東京都渋谷区本町三丁目１２ー１||^PRN^PH^^^^^^^^^03-1234-5678|||||||||||N||||||N|||20161028143309
            PV1||I
            IN1|1|06^組合管掌健康保険^JHSD0001|06050116|||||||９２０４５|１０|19990514|||||SEL^本人^HL70063
            ORC|NW|123456789012345||123456789012345_01_001|||||20160701012410|20002^更新^次郎^^^^^^^L^^^^^I||10001^医師^一郎^^^^^^^L^^^^^I|||||01^内科^99ILL|PC01^^99LWS|||||||||||I^入院患者オーダ^HL70482
            RXE||00^一般^JHSI0002|510||ml^ミリリッター^ISO+|INJ^注射剤^MR9P|^５時間一定速度で^JHSIC006|||||||30003^監査^三郎^^^^^^^L^^^^^I|20160701-001||||||IHP^入院処方^MR9P~FTP^定時処方^JHSI0001||102|ml/hr^ミリリッター／時間^ISO+|||02^点滴^JHSI0009||| ||||||||||||09A^^^^^N
            TQ1|1||||||201607010800|201607011300|||||5^hr
            RXR|IV^静脈内^HL70162|ARM^腕^HL70550||102^点滴静注(末梢)^99ILL|01^主管^99ILL|L^左^HL70495
            RXC|B|107750602^ソリタ－Ｔ３号輸液５００ｍＬ^HOT|1|HON^本^MR9P
            RXC|A|108010001^アドナ注（静脈用）５０ｍｇ^HOT|1|AMP^アンプル^MR9P
            ORC|NW|123456789012345||123456789012345_01_002|||||20160701012410|20002^更新^次郎^^^^^^^L^^^^^I||10001^医師^一郎^^^^^^^L^^^^^I|||||01^内科^99ILL|PC01^^99LWS|||||||||||I^入院患者オーダ^HL70482
            RXE||00^一般^JHSI0002|510||ml^ミリリッター^ISO+|INJ^注射剤^MR9P|^５時間一定速度で^JHSIC006|||||||30003^監査^三郎^^^^^^^L^^^^^I|20160701-001||||||IHP^入院処方^MR9P~FTP^定時処方^JHSI0001||102|ml/hr^ミリリッター／時間^ISO+|||02^点滴^JHSI0009|||||||||||||||09A^^^^^N
            TQ1|1||||||201607011300|201607011800|||||5^hr
            RXR|IV^静脈内^HL70162|ARM^腕^HL70550||102^点滴静注(末梢)^99ILL|01^主管^99ILL|L^左^HL70495
            RXC|B|107750602^ソリタ－Ｔ３号輸液５００ｍＬ^HOT|1|HON^本^MR9P
            RXC|A|108010001^アドナ注（静脈用）５０ｍｇ^HOT|1|AMP^アンプル^MR9P
            ORC|NW|123456789012345||123456789012345_01_003|||||20160701012410|20002^更新^次郎^^^^^^^L^^^^^I||10001^医師^一郎^^^^^^^L^^^^^I|||||01^内科^99ILL|PC01^^99LWS|||||||||||I^入院患者オーダ^HL70482
            RXE||00^一般^JHSI0002|510||ml^ミリリッター^ISO+|INJ^注射剤^MR9P|^５時間一定速度で^JHSIC006|||||||30003^監査^三郎^^^^^^^L^^^^^I|20160701-001||||||IHP^入院処方^MR9P~FTP^定時処方^JHSI0001||102|ml/hr^ミリリッター／時間^ISO+|||02^点滴^JHSI0009|||||||||||||||09A^^^^^N
            TQ1|1||||||201607011800|201607012300|||||5^hr
            RXR|IV^静脈内^HL70162|ARM^腕^HL70550||102^点滴静注(末梢)^99ILL|01^主管^99ILL|L^左^HL70495
            RXC|B|107750602^ソリタ－Ｔ３号輸液５００ｍＬ^HOT|1|HON^本^MR9P
            RXC|A|108010001^アドナ注（静脈用）５０ｍｇ^HOT|1|AMP^アンプル^MR9P
            ORC|NW|123456789012345||123456789012345_02_004|||||20160701012410|20002^更新^次郎^^^^^^^L^^^^^I||10001^医師^一郎^^^^^^^L^^^^^I|||||01^内科^99ILL|PC01^^99LWS|||||||||||I^入院患者オーダ^HL70482
            RXE||00^一般^JHSI0002|100||ml^ミリリッター^ISO+|INJ^注射剤^MR9P|^１時間一定速度で^JHSIC006|||||||30003^監査^三郎^^^^^^^L^^^^^I|20160701-001||||||IHP^入院処方^MR9P~FTP^定時処方^JHSI0001||100|ml/hr^ミリリッター／時間^ISO+|||02^点滴^JHSI0009|||||||||||||||09A^^^^^N
            TQ1|1||||||201607011000|201607011100|||||1^hr
            RXR|IV^静脈内^HL70162|ARM^腕^HL70550||102^点滴静注(末梢)^99ILL|02^側管^99ILL|L^左^HL70495
            RXC|B|107667701^生理食塩液100mL^HOT|1|HON^本^MR9P
            RXC|A|111177401^カルベニン注0.5g^HOT|2|VIL^バイアル^MR9P
            ORC|NW|123456789012345||123456789012345_02_005|||||20160701012410|20002^更新^次郎^^^^^^^L^^^^^I||10001^医師^一郎^^^^^^^L^^^^^I|||||01^内科^99ILL|PC01^^99LWS|||||||||||I^入院患者オーダ^HL70482
            RXE||00^一般^JHSI0002|100||ml^ミリリッター^ISO+|INJ^注射剤^MR9P|^１時間一定速度で^JHSIC006|||||||30003^監査^三郎^^^^^^^L^^^^^I|20160701-001||||||IHP^入院処方^MR9P~FTP^定時処方^JHSI0001||100|ml/hr^ミリリッター／時間^ISO+|||02^点滴^JHSI0009|||||||||||||||09A^^^^^N
            TQ1|1||||||201607011500|201607011600|||||1^hr
            RXR|IV^静脈内^HL70162|ARM^腕^HL70550||102^点滴静注(末梢)^99ILL|02^側管^99ILL|L^左^HL70495
            RXC|B|107667701^生理食塩液100mL^HOT|1|HON^本^MR9P
            RXC|A|111177401^カルベニン注0.5g^HOT|2|VIL^バイアル^MR9P
        MSG
    end

    it '#perform' do
        generator.perform
        expect(generator.get_resources.entry.count).to eq 11
    end
end