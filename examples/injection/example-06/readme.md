# 抗がん剤

## HL7v2
```
MSH|^~¥&|SEND||RECEIVE||20161201012213.225||RDE^O11^RDE_O11|20161201012213225|P|2.5||||||~ISOIR87||ISO 2022-1994
PID|||0099999999^^^^PI||テスト^太郎^^^^^L^I~テスト^タロウ^^^^^L^P||19750219|M
PV1||I
IN1|1|06^組合管掌健康保険^JHSD0001|""
AL1|1|FA^食物アレルギー^HL70127|20001^ソバ^99ZAL|MO^中程度^HL70128
ORC|NW|000000000101001||000000000101001_01_001|||||20161201012410|9999^テスト^看護師^^^^^^^L^^^^^I||1111^テスト^医師^^^^^^^L^^^^^I|||||01^内科^99ILL|WSN0001^^99LWS|||||||||||I^入院患者オーダ^HL70482
RXE||07^抗がん剤^JHSI0002|60.3||ml^ミリリッター^ISO+|INJ^注射剤^MR9P|^オーダ時体表面積 1.915 ㎡ 体表面積あたりの100％量 45mg^JHSIC007~^投与上限値 112.5ml 投与下限値 40ml オーダ指示量 100%^JHSIC007~^医師が施行^JHSIC004~^緩徐に静注^JHSIC003~^できるだけ太い静脈を使用^JHSIC003||||||||20161201-001||||||IHP^入院処方^MR9P~FTP^定時処方^JHSI0001||240|ml/hr^ミリリッター／時間^ISO＋|||02^点滴^JHSI0009|||||||||||||||05B^^^^^N
TQ1|1||||||201612011000|201612011005|R^ルーチン^HL70485
RXR|IV^静脈内^HL70162|ARM^腕^HL70550|IVP^点滴ポンプ^HL70164|102^点滴静注(末梢)^99ILL||L^左^HL70495
RXC|A|115107702^カルセド注射用２０ｍｇ^HOT|3|BTL^瓶^MR9P|||03^抗がん剤^JHSI0004
RXC|B|107660801^大塚生食注 ２０ｍＬ^HOT|1|AMP^管^MR9P
OBX|1|NM|8302-2^身長^LN||170.0|cm^cm^ISO+|||||F|||20160703
OBX|2|NM|3141-9^体重^LN||80.0|kg^kg^ISO+|||||F|||20160703
OBX|3|NM|3140-1^体表面積^LN||1.915|m2^m2^ISO+|||||F|||20160703
```