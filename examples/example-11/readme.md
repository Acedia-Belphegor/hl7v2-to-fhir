# 在宅自己注射

## 処方せん表記の参考例
```
Rp1 ヒューマリンＮ注        ５０単位（１日５０単位）
    　１日１回朝食前        １４日分
```

## HL7v2
```
MSH|^~\&|SEND||RECEIVE||20160821161523||RDE^O11^RDE_O11|201608211615230143|P|2.5||||||~ISOIR87||ISO 2022-1994
PID|||1000000001^^^^PI||患者^太郎^^^^^L^I~カンジャ^タロウ^^^^^L^P||19601224|M
IN1|1|06^組合管掌健康保険^JHSD0001|""
ORC|NW|12345678||12345678_01|||||20160821|||123456^医師^春子^^^^^^^L^^^^^I~^イシ^ハルコ^^^^^^^L^^^^^P|||||01^内科^99Z01||||||||||||O^外来患者オーダ^HL70482
RXE||105466802^ヒューマリンＮ注１００単位／ｍＬ^HOT|50||UNT^単位^MR9P|INJ^注射剤^MR9P||||700|UNT^単位^MR9P||||||||50^UNT&単位&MR9P||OHP^外来処方^MR9P~OHO^院外処方^MR9P||||||24^自己注射^JHSP0003
TQ1|||3211000200000014&注射・皮下注射・ １ 日 １ 回 朝 食直前・ワンショット・在宅・自己&JAMISDP01|||14^D&日&ISO+|20160825
RXR|SC^皮下^HL70162
```

## FHIR
- [json](https://github.com/Acedia-Belphegor/hl7v2-to-fhir/blob/master/examples/example-11/example_11.json)

- [xml](https://github.com/Acedia-Belphegor/hl7v2-to-fhir/blob/master/examples/example-11/example_11.xml)