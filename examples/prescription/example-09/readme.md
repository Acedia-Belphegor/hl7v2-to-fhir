# 不均等投与

## 処方せん表記の参考例
```
Rp01 プレドニン錠５ｍｇ         朝4錠、昼2錠、夕方1錠（１日７錠）
    　１日３回朝昼夕食後        ７日分
```

## HL7v2
```
MSH|^~\&|SEND||RECEIVE||20160821161523||RDE^O11^RDE_O11|201608211615230143|P|2.5||||||~ISO IR87||ISO 2022-1994
PID|||1000000001^^^^PI||患者^太郎^^^^^L^I~カンジャ^タロウ^^^^^L^P||19601224|M
IN1|1|06^組合管掌健康保険^JHSD0001|""
ORC|NW|12345678||12345678_01|||||20160821104529|123456^医師^春子^^^^^^^L^^^^^I~^イシ^ハルコ^^^^^^^L^^^^^P||123456^医師^春子^^^^^^^L^^^^^I~^イシ^ハルコ^^^^^^^L^^^^^P|||||01^内科^99Z01||||||||||||O^外来患者オーダ^HL70482
RXE||105271807^プレドニン錠５ｍｇ^HOT|1|4|TAB^錠^MR9P||V14NNNNN^４錠^JAMISDP01~V22NNNNN^２錠^JAMISDP01~V31NNNNN^１錠^JAMISDP01|||49|TAB^錠^MR9P||||||||7^TAB&錠&MR9P||OHP^外来処方^MR9P~OHI^院内処方^MR9P||||||21^内服薬^JHSP0003
TQ1|||1013044400000000&内服・経口・１日３回朝昼夕食後&JAMISDP01|||7^D&日&ISO+|20160825
RXR|PO^口^HL70162
```

## FHIR
- [json](https://github.com/Acedia-Belphegor/hl7v2-to-fhir/blob/master/examples/example-09/example_09.json)

- [xml](https://github.com/Acedia-Belphegor/hl7v2-to-fhir/blob/master/examples/example-09/example_09.xml)