# 頓服薬

## 処方せん表記の参考例
```
Rp1 ボルタレン錠(25ｍg)     １錠
    　疼痛時            １０回分
    　１日２回まで
```

## HL7v2
```
MSH|^~\&|SEND||RECEIVE||20160821161523||RDE^O11^RDE_O11|201608211615230143|P|2.5||||||~ISOIR87||ISO 2022-1994
PID|||1000000001^^^^PI||患者^太郎^^^^^L^I~カンジャ^タロウ^^^^^L^P||19601224|M
IN1|1|06^組合管掌健康保険^JHSD0001|""
ORC|NW|12345678||12345678_01|||||20160821|||123456^医師^春子^^^^^^^L^^^^^I~^イシ^ハルコ^^^^^^^L^^^^^P|||||01^内科^99Z01||||||||||||O^外来患者オーダ^HL70482
RXE||100795402^ボルタレン錠２５ｍｇ^HOT|1||TAB^錠^MR9P|||||10|TAB^錠^MR9P||||||||||OHP^外来処方^MR9P~OHI^院内処方^MR9P||||||22^頓用^JHSP0003
TQ1|||1050110020000000&内服・経口・疼痛時&JAMISDP01||||20160825||||1 日2 回まで|||10
RXR|PO^口^HL70162
```

## FHIR
- [json](https://github.com/Acedia-Belphegor/hl7v2-to-fhir/blob/master/examples/prescription/example-05/example_05.json)

- [xml](https://github.com/Acedia-Belphegor/hl7v2-to-fhir/blob/master/examples/prescription/example-05/example_05.xml)