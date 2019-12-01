# encoding: utf-8

# RDE^O11:処方依頼
def get_example_rde_prescription()
    return <<~MSG
        MSH|^~\&|HL7v2|1319999999|HL7FHIR|1319999999|20160821161523||RDE^O11^RDE_O11|201608211615230143|P|2.5||||||~ISOIR87||ISO 2022-1994
        PID|||1000000001^^^^PI||患者^太郎^^^^^L^I~カンジャ^タロウ^^^^^L^P||19791101|M|||^^渋谷区^東京都^1510071^JPN^H^東京都渋谷区本町三丁目１２ー１||^PRN^PH^^^^^^^^^03-1234-5678|||||||||||N||||||N|||20161028143309
        IN1|1|06^組合管掌健康保険^JHSD0001|06050116|||||||９２０４５|１０|19990514|||||SEL^本人^HL70063
        ORC|NW|12345678||12345678_01|||||20160825|||123456^医師^春子^^^^^^^L^^^^^I~^イシ^ハルコ^^^^^^^L^^^^^P|||||01^内科^99Z01||||メドレークリニック|^^港区^東京都^^JPN^^東京都港区六本木３−２−１|||||||O^外来患者オーダ^HL70482
        RXE||103835401^ムコダイン錠２５０ｍｇ^HOT|1||TAB^錠^MR9P|TAB^錠^MR9P|01^１回目から服用^JHSP0005|||9|TAB^錠^MR9P||||||||3^TAB&錠&MR9P||OHP^外来処方^MR9P~OHI^院内処方^MR9P||||||21^内服^JHSP0003
        TQ1|||1013044400000000&内服・経口・１日３回朝昼夕食後&JAMISDP01|||3^D&日&ISO+|20160825
        RXR|PO^口^HL70162
        ORC|NW|12345678||12345678_01|||||20160825|||123456^医師^春子^^^^^^^L^^^^^I~^イシ^ハルコ^^^^^^^L^^^^^P|||||01^内科^99Z01||||メドレークリニック|^^港区^東京都^^JPN^^東京都港区六本木３−２−１|||||||O^外来患者オーダ^HL70482
        RXE||110626901^パンスポリンＴ錠１００ １００ｍｇ^HOT|2||TAB^錠^MR9P|TAB^錠^MR9P|01^１回目から服用^JHSP0005|||18|TAB^錠^MR9P||||||||6^TAB&錠&MR9P||OHP^外来処方^MR9P~OHI^院内処方^MR9P||||||21^内服^JHSP0003
        TQ1|||1013044400000000&内服・経口・１日３回朝昼夕食後&JAMISDP01|||3^D&日&ISO+|20160825
        RXR|PO^口^HL70162
        ORC|NW|12345678||12345678_02|||||20160825|||123456^医師^春子^^^^^^^L^^^^^I~^イシ^ハルコ^^^^^^^L^^^^^P|||||01^内科^99Z01||||メドレークリニック|^^港区^東京都^^JPN^^東京都港区六本木３−２−１|||||||O^外来患者オーダ^HL70482
        RXE||100795402^ボルタレン錠２５ｍｇ^HOT|1||TAB^錠^MR9P|||||10|TAB^錠^MR9P||||||||||OHP^外来処方^MR9P~OHI^院内処方^MR9P||||||22^頓用^JHSP0003
        TQ1|||1050110020000000&内服・経口・疼痛時&JAMISDP01||||20160825||||1 日2 回まで|||10
        RXR|PO^口^HL70162
        ORC|NW|12345678||12345678_03|||||20160825|||123456^医師^春子^^^^^^^L^^^^^I~^イシ^ハルコ^^^^^^^L^^^^^P|||||01^内科^99Z01||||メドレークリニック|^^港区^東京都^^JPN^^東京都港区六本木３−２−１|||||||O^外来患者オーダ^HL70482
        RXE||106238001^ジフラール軟膏０．０５％^HOT|""||""|OIT^軟膏^MR9P||||2|HON^本^MR9P||||||||||OHP^外来処方^MR9P~OHO^院外処方^MR9P||||||23^外用^JHSP0003
        TQ1|||2B74000000000000&外用・塗布・１日４回&JAMISDP01||||20160825
        RXR|AP^外用^HL70162|77L^左手^JAMISDP01
    MSG
end

# RDE^O11:注射依頼
def get_example_rde_injection
    return <<~MSG
        MSH|^~¥&|SEND||RECEIVE||20160701012213.225||RDE^O11^RDE_O11|20160701012213225|P|2.5||||||~ISOIR87||ISO 2022-1994
        PID|||0012345678^^^^PI||患者^太郎^^^^^L^I~カンジャ^タロウ^^^^^L^P||19650415|M
        PV1||I
        IN1|1|06^組合管掌健康保険^JHSD0001|""
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

# OUL^R22:検査結果
def get_example_oul()
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

# ADT^A08:患者情報更新
def get_example_adt()
    return <<~MSG
        MSH|^~\&|HL7v2|1319999999|HL7FHIR|1319999999|20161028143312.3521||ADT^A08^ADT_A01|20161028000000002134|P|2.5||||||~ISO IR87||ISO 2022-1994|SS-MIX2_1.20^SS-MIX2^1.2.392.200250.2.1.100.1.2.120^ISO
        EVN||20161028143309|||D100||送信施設
        PID|0001||99990010||テスト^患者１０^^^^^L^I~テスト^カンジャ10^^^^^L^P||19791101|M|||^^^^1510071^JPN^H^東京都渋谷区本町三丁目１２番１号住友不動産西新宿ビル６号館||^PRN^PH^^^^^^^^^03-1234-5678||||||||||||||||||||20161028143309||||||
        NK1|1|テスト^花子^^^^^L^I|^実母^99zzz||^PRN^PH^^^^^^^^^090-xxxx-xxxx||||||||
        PV1|0001|O|01^^^^^C||||||||||||||||||||||||||||||||||||||||||
        DB1|1|PT||N
        OBX|1|NM|9N001000000000001^身長^JC10||165.10|cm^cm^ISO+|||||F||||||||
        OBX|2|NM|9N006000000000001^体重^JC10||51.20|kg^kg^ISO+|||||F||||||||
        AL1|1|DA^薬剤アレルギー^HL70127|11I^ヨード^99zzz|||
        AL1|2|FA^食物アレルギー^HL70127|237^青魚^99zzz|||
        AL1|3|MA^様々なアレルギー^HL70127|351^花粉症^99zzz|||
        IAM|1|LA^花粉アレルギー^HL70127|5A1002216023023^スギ^JC10|MI^軽度^HL70128|目のかゆみ|A^追加^HL70323|||||199601
        IAM|2|FA^食物アレルギー^HL70127|5A1002411023006^ソバ^JC10|MO^中等度^HL70128|湿疹|A^追加^HL70323||||||小学校低学年の頃
        IAM|3|EA^環境アレルギー^HL70127|5A1102700023023^ハウスダスト^JC10|MI^軽度^HL70128|くしゃみ|A^追加^HL70323|||||200302
        IAM|4|DA^薬剤アレルギー^HL70127|106824501^アリナミン^HOT9|MO^中等度^HL70128|のどの渇きが止まらない|A^追加^HL70323|||||20070710
        IN1|1|06^組合管掌健康保険^JHSD0001|06050116|||||||９２０４５|１０|19990514|||||SEL^本人^HL70063
    MSG
end
