# 曜日指定投与

## 処方せん表記の参考例
```
Rp01 プレドニン錠５ｍｇ     ３錠
    　１日１回朝食後        ７日分
    　月曜日、木曜日に服用
```

## HL7v2
```
MSH|^~\&|SEND||RECEIVE||20160821161523||RDE^O11^RDE_O11|201608211615230143|P|2.5||||||~ISOIR87||ISO 2022-1994
PID|||1000000001^^^^PI||患者^太郎^^^^^L^I~カンジャ^タロウ^^^^^L^P||19601224|M
IN1|1|06^組合管掌健康保険^JHSD0001|""
ORC|NW|12345678||12345678_01|||||20160825|||123456^医師^春子^^^^^^^L^^^^^I~^イシ^ハルコ^^^^^^^L^^^^^P|||||01^内科^99Z01||||||||||||O^外来患者オーダ^HL70482
RXE||105271807^プレドニン錠５ｍｇ^HOT|3||TAB^錠^MR9P|||||21|TAB^錠^MR9P||||||||3^TAB&錠&MR9P||OHP^外来処方^MR9P~OHO^院外処方^MR9P||||||21^内服^JHSP0003
TQ1|||1011000400000000&内服・経口・１日１回朝食後&JAMISDP01~ W0100100&月曜日、木曜日&JAMISDP01|||7^D&日&ISO+|20160825
RXR|PO^口^HL70162
```

## FHIR
- [json](https://github.com/Acedia-Belphegor/hl7v2-to-fhir/blob/master/examples/prescription/example-08/example_08.json)

- [xml](https://github.com/Acedia-Belphegor/hl7v2-to-fhir/blob/master/examples/prescription/example-08/example_08.xml)