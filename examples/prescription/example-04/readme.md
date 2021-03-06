# 麻薬

## 処方せん表記の参考例
```
Rp01 ＭＳコンチン錠１０ｍｇ   ４錠
    　１日２回（１２時間毎）  ７日分
```

## HL7v2
```
MSH|^~\&|SEND||RECEIVE||20160821161523||RDE^O11^RDE_O11|201608211615230143|P|2.5||||||~ISO IR87||ISO 2022-1994
PID|||1000000001^^^^PI||患者^太郎^^^^^L^I~カンジャ^タロウ^^^^^L^P||19601224|M
IN1|1|06^組合管掌健康保険^JHSD0001|""
ORC|NW|12345678||12345678_01|||||20160821120000|123456^医師^春子^^^^^^^L^^^^^I~^イシ^ハルコ^^^^^^^L^^^^^P||123456^医師^春子^^^^^^^L^^^^^I~^イシ^ハルコ^^^^^^^L^^^^^P|||||01^内科^99Z01||||||||||||I^入院患者オーダ^HL70482
RXE||112052301^ＭＳコンチン錠１０ｍｇ^HOT|2||TAB^錠^MR9P||02^２回目から服用^JHSP0005|||28|TAB^錠^MR9P||4-321^医師^春子^^^^^^L^^^^^I||||||4^TAB&錠&MR9P||IHP^入院処方^MR9P~XTR^定期処方^MR9P||||||21^内服^JHSP0003
TQ1|||1022000000000000&内服・経口・１日２回１２時間毎&JAMISDP01|||7^D&日&ISO+|20160825
RXR|PO^口^HL70162
```

## FHIR
- [json](https://github.com/Acedia-Belphegor/hl7v2-to-fhir/blob/master/examples/prescription/example-04/example_04.json)

- [xml](https://github.com/Acedia-Belphegor/hl7v2-to-fhir/blob/master/examples/prescription/example-04/example_04.xml)