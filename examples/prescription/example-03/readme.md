# 坐薬

## 処方せん表記の参考例
```
Rp1 ボラギノールＮ坐薬      １個（１日２個）
    　１日２回朝夕        １４日分
```

## HL7v2
```
MSH|^~\&|SEND||RECEIVE||20160821161523||RDE^O11^RDE_O11|201608211615230143|P|2.5||||||~ISOIR87||ISO 2022-1994
PID|||1000000001^^^^PI||患者^太郎^^^^^L^I~カンジャ^タロウ^^^^^L^P||19601224|M
IN1|1|06^組合管掌健康保険^JHSD0001|""
ORC|NW|12345678||12345678_01|||||20160821|||123456^医師^春子^^^^^^^L^^^^^I~^イシ^ハルコ^^^^^^^L^^^^^P|||||01^内科^99Z01||||||||||||O^外来患者オーダ^HL70482
RXE||105625901^ボラギノールＮ坐薬 ^HOT|1||KO^ 個 ^MR9P|SUP^ 坐 剤 ^MR9P||||28|KO^ 個^MR9P||||||||2^KO&個&MR9P||OHP^外来処方^MR9P~OHO^院外処方^MR9P||||||23^外用^JHSP0003
TQ1|||2R62090900000000&外用・肛門挿入・１日２回朝夕&JAMISDP01|||14^D&日&ISO+|20160825
RXR|PR^直腸^HL70162|8H0^肛門部^JAMISDP01
```

## FHIR
- [json](https://github.com/Acedia-Belphegor/hl7v2-to-fhir/blob/master/examples/prescription/example-03/example_03.json)

- [xml](https://github.com/Acedia-Belphegor/hl7v2-to-fhir/blob/master/examples/prescription/example-03/example_03.xml)