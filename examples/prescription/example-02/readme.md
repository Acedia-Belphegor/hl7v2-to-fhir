# 外用薬

## 処方せん表記の参考例
```
Rp01 ジフラール軟膏 ０．０５％      ２本
    　（塗布薬）１日４回
    　　左手
```

## HL7v2
```
MSH|^~\&|SEND||RECEIVE||20160825161523||RDE^O11^RDE_O11|201608251615230143|P|2.5||||||~ISOIR87||ISO 2022-1994
PID|||1000000001^^^^PI||患者^太郎^^^^^L^I~カンジャ^タロウ^^^^^L^P||19601224|M
IN1|1|06^組合管掌健康保険^JHSD0001|""
ORC|NW|12345678||12345678_01|||||20160825134500|123456^医師^春子^^^^^^^L^^^^^I~^イシ^ハルコ^^^^^^^L^^^^^P||123456^医師^春子^^^^^^^L^^^^^I~^イシ^ハルコ^^^^^^^L^^^^^P|||||01^内科^99Z01||||||||||||O^外来患者オーダ^HL70482
RXE||106238001^ジフラール軟膏０．０５％^HOT|""||""|OIT^軟膏^MR9P||||2|HON^本^MR9P||||||||||OHP^外来処方^MR9P~OHO^院外処方^MR9P||||||23^外用^JHSP0003
TQ1|||2B74000000000000&外用・塗布・１日４回&JAMISDP01||||20160825
RXR|AP^外用^HL70162|77L^左手^JAMISDP01
```

## FHIR
- [json](https://github.com/Acedia-Belphegor/hl7v2-to-fhir/blob/master/examples/prescription/example-02/example_02.json)

- [xml](https://github.com/Acedia-Belphegor/hl7v2-to-fhir/blob/master/examples/prescription/example-02/example_02.xml)