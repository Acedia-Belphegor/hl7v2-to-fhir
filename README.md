# HL7v2 to FHIR Conversion API

## fhir_prescription_generators

  | Contents | Description |
  | :--- | :--- |
  | 概要 | HL7v2処方オーダーメッセージをFHIRリソースに変換するAPI |
  | URI | `POST` /api/hl7/fhir_prescription_generators.json (.xml) |
  | Encoding | UTF-8 |
  | Request | HL7v2メッセージ(RDE^O11) |
  | Response | FHIRリソース(JSON/XML) |

## fhir_inspection_result_generators

  | Contents | Description |
  | :--- | :--- |
  | 概要 | HL7v2検査結果メッセージをFHIRリソースに変換するAPI |
  | URI | `POST` /api/hl7/fhir_inspection_result_generators.json (.xml) |
  | Encoding | UTF-8 |
  | Request | HL7v2メッセージ(OUL^R22) |
  | Response | FHIRリソース(JSON/XML) |

## fhir_patient_generators

  | Contents | Description |
  | :--- | :--- |
  | 概要 | HL7v2患者情報更新メッセージをFHIRリソースに変換するAPI |
  | URI | `POST` /api/hl7/fhir_patient_generators.json (.xml) |
  | Encoding | UTF-8 |
  | Request | HL7v2メッセージ(ADT^A08) |
  | Response | FHIRリソース(JSON/XML) |

## notes
  - request-bodyのHL7v2メッセージに`<EOM>(0x1C,0x0D)`は設定しない
  - MSH-3.Sending Facilityには `都道府県番号` + `点数表番号` + `医療機関コード` を設定する (ex: 1319999999)

## example

Request Body
```
MSH|^~\&|HL7v2|1319999999|HL7FHIR|1319999999|20160821161523||RDE^O11^RDE_O11|201608211615230143|P|2.5||||||~ISOIR87||ISO 2022-1994
PID|||1000000001^^^^PI||患者^太郎^^^^^L^I~カンジャ^タロウ^^^^^L^P||19791101|M|||^^渋谷区^東京都^1510071^JPN^H^東京都渋谷区本町三丁目１２ー１||^PRN^PH^^^^^^^^^03-1234-5678
IN1|1|06^組合管掌健康保険^JHSD0001|06050116|||||||９２０４５|１０|19990514|||||SEL^本人^HL70063
IN1|2|15^障害者総合支援法 更正医療^JHSD0001|15138092|障害者総合支援 更正医療（東京都）
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
```

Response Body (json)
```
{
  "type": "message",
  "entry": [
    {
      "resource": {
        "id": "0",
        "eventCoding": {
          "system": "http://www.hl7fhir.jp",
          "code": "RDE^O11^RDE_O11"
        },
        "destination": [
          {
            "name": "HL7FHIR"
          }
        ],
        "source": {
          "name": "HL7v2"
        },
        "resourceType": "MessageHeader"
      }
    },
    {
      "resource": {
        "id": "0",
        "identifier": [
          {
            "system": "OID:1.2.392.100495.20.3.51.11319999999",
            "value": "1000000001"
          }
        ],
        "name": [
          {
            "extension": [
              {
                "url": "http://hl7.org/fhir/StructureDefinition/iso21090-EN-representation",
                "valueCode": "IDE"
              }
            ],
            "use": "official",
            "family": "患者",
            "given": [
              "太郎"
            ]
          },
          {
            "extension": [
              {
                "url": "http://hl7.org/fhir/StructureDefinition/iso21090-EN-representation",
                "valueCode": "SYL"
              }
            ],
            "use": "official",
            "family": "カンジャ",
            "given": [
              "タロウ"
            ]
          }
        ],
        "telecom": [
          {
            "system": "phone",
            "value": "03-1234-5678",
            "use": "home"
          }
        ],
        "gender": "male",
        "birthDate": "1979-11-01",
        "address": [
          {
            "line": [
              "東京都渋谷区本町三丁目１２ー１"
            ],
            "city": "渋谷区",
            "state": "東京都",
            "postalCode": "1510071",
            "country": "JPN"
          }
        ],
        "resourceType": "Patient"
      }
    },
    {
      "resource": {
        "id": "0",
        "identifier": [
          {
            "system": "OID:1.2.392.100495.20.3.61",
            "value": "06050116"
          },
          {
            "system": "OID:1.2.392.100495.20.3.62",
            "value": "９２０４５"
          },
          {
            "system": "OID:1.2.392.100495.20.3.63",
            "value": "１０"
          }
        ],
        "type": {
          "coding": [
            {
              "system": "1.2.392.100495.20.2.61",
              "code": "1",
              "display": "社保"
            }
          ]
        },
        "beneficiary": {
          "id": "0",
          "type": "Patient"
        },
        "relationship": {
          "coding": [
            {
              "system": "1.2.392.100495.20.2.61",
              "code": "1",
              "display": "被保険者"
            }
          ]
        },
        "payor": [
          {
            "id": "dummy",
            "type": "Organization"
          }
        ],
        "resourceType": "Coverage"
      }
    },
    {
      "resource": {
        "id": "1",
        "identifier": [
          {
            "system": "OID:1.2.392.100495.20.3.71",
            "value": "15138092"
          }
        ],
        "type": {
          "coding": [
            {
              "system": "1.2.392.100495.20.2.61",
              "code": "8",
              "display": "公費"
            }
          ]
        },
        "beneficiary": {
          "id": "0",
          "type": "Patient"
        },
        "payor": [
          {
            "id": "dummy",
            "type": "Organization"
          }
        ],
        "resourceType": "Coverage"
      }
    },
    {
      "resource": {
        "id": "0",
        "identifier": [
          {
            "system": "OID:1.2.392.100495.20.3.41.11319999999",
            "value": "123456"
          }
        ],
        "name": [
          {
            "extension": [
              {
                "url": "http://hl7.org/fhir/StructureDefinition/iso21090-EN-representation",
                "valueCode": "IDE"
              }
            ],
            "family": "医師",
            "given": [
              "春子"
            ]
          },
          {
            "extension": [
              {
                "url": "http://hl7.org/fhir/StructureDefinition/iso21090-EN-representation",
                "valueCode": "SYL"
              }
            ],
            "family": "イシ",
            "given": [
              "ハルコ"
            ]
          }
        ],
        "resourceType": "Practitioner"
      }
    },
    {
      "resource": {
        "id": "0",
        "identifier": [
          {
            "system": "OID:1.2.392.100495.20.3.41.11319999999",
            "value": "123456"
          }
        ],
        "code": [
          {
            "coding": [
              {
                "system": "http://terminology.hl7.org/CodeSystem/practitioner-role",
                "code": "doctor",
                "display": "Doctor"
              }
            ]
          }
        ],
        "specialty": [
          {
            "coding": [
              {
                "system": "99Z01",
                "code": "01",
                "display": "内科"
              }
            ]
          }
        ],
        "resourceType": "PractitionerRole"
      }
    },
    {
      "resource": {
        "id": "0",
        "identifier": [
          {
            "system": "OID:1.2.392.100495.20.3.21",
            "value": "13"
          },
          {
            "system": "OID:1.2.392.100495.20.3.22",
            "value": "1"
          },
          {
            "system": "OID:1.2.392.100495.20.3.23",
            "value": "9999999"
          }
        ],
        "name": "メドレークリニック",
        "address": [
          {
            "line": [
              "東京都港区六本木３−２−１"
            ],
            "city": "港区",
            "state": "東京都",
            "country": "JPN"
          }
        ],
        "resourceType": "Organization"
      }
    },
    {
      "resource": {
        "id": "0",
        "identifier": [
          {
            "system": "OID:1.2.392.100495.20.3.11",
            "value": "12345678"
          },
          {
            "system": "OID:1.2.392.100495.20.3.81",
            "value": "12345678_01"
          }
        ],
        "status": "draft",
        "intent": "order",
        "category": [
          {
            "coding": [
              {
                "system": "MR9P",
                "code": "TAB",
                "display": "錠"
              }
            ]
          },
          {
            "coding": [
              {
                "system": "JHSP0003",
                "code": "21",
                "display": "内服"
              }
            ]
          }
        ],
        "medicationCodeableConcept": {
          "coding": [
            {
              "system": "OID:1.2.392.100495.20.2.74",
              "code": "103835401",
              "display": "ムコダイン錠２５０ｍｇ"
            }
          ]
        },
        "subject": {
          "id": "0",
          "type": "Patient"
        },
        "authoredOn": "2016-08-25",
        "insurance": [
          {
            "id": "0",
            "type": "Coverage"
          },
          {
            "id": "1",
            "type": "Coverage"
          }
        ],
        "dosageInstruction": [
          {
            "text": "内服・経口・１日３回朝昼夕食後",
            "additionalInstruction": [
              {
                "coding": [
                  {
                    "system": "JHSP0005",
                    "code": "01",
                    "display": "１回目から服用"
                  }
                ]
              }
            ],
            "timing": {
              "event": [
                "2016-08-25T00:00:00+00:00"
              ],
              "repeat": {
                "period": 3,
                "periodUnit": "d"
              },
              "code": [
                {
                  "coding": [
                    {
                      "system": "JAMISDP01",
                      "code": "1013044400000000",
                      "display": "内服・経口・１日３回朝昼夕食後"
                    }
                  ]
                }
              ]
            },
            "route": {
              "coding": [
                {
                  "system": "HL70162",
                  "code": "PO",
                  "display": "口"
                }
              ]
            },
            "doseAndRate": [
              {
                "type": {
                  "coding": [
                    {
                      "system": "LC",
                      "code": "Give Amount - Minimum",
                      "display": "与薬量－最小"
                    }
                  ]
                },
                "doseQuantity": {
                  "value": 1,
                  "unit": "錠",
                  "code": "TAB"
                }
              },
              {
                "type": {
                  "coding": [
                    {
                      "system": "LC",
                      "code": "Total Daily Dose",
                      "display": "1 日あたりの総投与量"
                    }
                  ]
                },
                "doseQuantity": {
                  "value": 3,
                  "unit": "錠",
                  "code": "TAB"
                }
              }
            ]
          }
        ],
        "dispenseRequest": {
          "quantity": {
            "value": 9,
            "unit": "錠",
            "code": "TAB"
          }
        },
        "resourceType": "MedicationRequest"
      }
    },
    {
      "resource": {
        "id": "1",
        "identifier": [
          {
            "system": "OID:1.2.392.100495.20.3.11",
            "value": "12345678"
          },
          {
            "system": "OID:1.2.392.100495.20.3.81",
            "value": "12345678_01"
          }
        ],
        "status": "draft",
        "intent": "order",
        "category": [
          {
            "coding": [
              {
                "system": "MR9P",
                "code": "TAB",
                "display": "錠"
              }
            ]
          },
          {
            "coding": [
              {
                "system": "JHSP0003",
                "code": "21",
                "display": "内服"
              }
            ]
          }
        ],
        "medicationCodeableConcept": {
          "coding": [
            {
              "system": "OID:1.2.392.100495.20.2.74",
              "code": "110626901",
              "display": "パンスポリンＴ錠１００ １００ｍｇ"
            }
          ]
        },
        "subject": {
          "id": "0",
          "type": "Patient"
        },
        "authoredOn": "2016-08-25",
        "insurance": [
          {
            "id": "0",
            "type": "Coverage"
          },
          {
            "id": "1",
            "type": "Coverage"
          }
        ],
        "dosageInstruction": [
          {
            "text": "内服・経口・１日３回朝昼夕食後",
            "additionalInstruction": [
              {
                "coding": [
                  {
                    "system": "JHSP0005",
                    "code": "01",
                    "display": "１回目から服用"
                  }
                ]
              }
            ],
            "timing": {
              "event": [
                "2016-08-25T00:00:00+00:00"
              ],
              "repeat": {
                "period": 3,
                "periodUnit": "d"
              },
              "code": [
                {
                  "coding": [
                    {
                      "system": "JAMISDP01",
                      "code": "1013044400000000",
                      "display": "内服・経口・１日３回朝昼夕食後"
                    }
                  ]
                }
              ]
            },
            "route": {
              "coding": [
                {
                  "system": "HL70162",
                  "code": "PO",
                  "display": "口"
                }
              ]
            },
            "doseAndRate": [
              {
                "type": {
                  "coding": [
                    {
                      "system": "LC",
                      "code": "Give Amount - Minimum",
                      "display": "与薬量－最小"
                    }
                  ]
                },
                "doseQuantity": {
                  "value": 2,
                  "unit": "錠",
                  "code": "TAB"
                }
              },
              {
                "type": {
                  "coding": [
                    {
                      "system": "LC",
                      "code": "Total Daily Dose",
                      "display": "1 日あたりの総投与量"
                    }
                  ]
                },
                "doseQuantity": {
                  "value": 6,
                  "unit": "錠",
                  "code": "TAB"
                }
              }
            ]
          }
        ],
        "dispenseRequest": {
          "quantity": {
            "value": 18,
            "unit": "錠",
            "code": "TAB"
          }
        },
        "resourceType": "MedicationRequest"
      }
    },
    {
      "resource": {
        "id": "2",
        "identifier": [
          {
            "system": "OID:1.2.392.100495.20.3.11",
            "value": "12345678"
          },
          {
            "system": "OID:1.2.392.100495.20.3.81",
            "value": "12345678_02"
          }
        ],
        "status": "draft",
        "intent": "order",
        "category": [
          {
            "coding": [
              {
                "system": "JHSP0003",
                "code": "22",
                "display": "頓用"
              }
            ]
          }
        ],
        "medicationCodeableConcept": {
          "coding": [
            {
              "system": "OID:1.2.392.100495.20.2.74",
              "code": "100795402",
              "display": "ボルタレン錠２５ｍｇ"
            }
          ]
        },
        "subject": {
          "id": "0",
          "type": "Patient"
        },
        "authoredOn": "2016-08-25",
        "insurance": [
          {
            "id": "0",
            "type": "Coverage"
          },
          {
            "id": "1",
            "type": "Coverage"
          }
        ],
        "dosageInstruction": [
          {
            "text": "内服・経口・疼痛時",
            "patientInstruction": "1 日2 回まで",
            "timing": {
              "event": [
                "2016-08-25T00:00:00+00:00"
              ],
              "code": [
                {
                  "coding": [
                    {
                      "system": "JAMISDP01",
                      "code": "1050110020000000",
                      "display": "内服・経口・疼痛時"
                    }
                  ]
                }
              ]
            },
            "route": {
              "coding": [
                {
                  "system": "HL70162",
                  "code": "PO",
                  "display": "口"
                }
              ]
            },
            "doseAndRate": [
              {
                "type": {
                  "coding": [
                    {
                      "system": "LC",
                      "code": "Give Amount - Minimum",
                      "display": "与薬量－最小"
                    }
                  ]
                },
                "doseQuantity": {
                  "value": 1,
                  "unit": "錠",
                  "code": "TAB"
                }
              }
            ]
          }
        ],
        "dispenseRequest": {
          "quantity": {
            "value": 10,
            "unit": "錠",
            "code": "TAB"
          }
        },
        "resourceType": "MedicationRequest"
      }
    },
    {
      "resource": {
        "id": "3",
        "identifier": [
          {
            "system": "OID:1.2.392.100495.20.3.11",
            "value": "12345678"
          },
          {
            "system": "OID:1.2.392.100495.20.3.81",
            "value": "12345678_03"
          }
        ],
        "status": "draft",
        "intent": "order",
        "category": [
          {
            "coding": [
              {
                "system": "MR9P",
                "code": "OIT",
                "display": "軟膏"
              }
            ]
          },
          {
            "coding": [
              {
                "system": "JHSP0003",
                "code": "23",
                "display": "外用"
              }
            ]
          }
        ],
        "medicationCodeableConcept": {
          "coding": [
            {
              "system": "OID:1.2.392.100495.20.2.74",
              "code": "106238001",
              "display": "ジフラール軟膏０．０５％"
            }
          ]
        },
        "subject": {
          "id": "0",
          "type": "Patient"
        },
        "authoredOn": "2016-08-25",
        "insurance": [
          {
            "id": "0",
            "type": "Coverage"
          },
          {
            "id": "1",
            "type": "Coverage"
          }
        ],
        "dosageInstruction": [
          {
            "text": "外用・塗布・１日４回",
            "timing": {
              "event": [
                "2016-08-25T00:00:00+00:00"
              ],
              "code": [
                {
                  "coding": [
                    {
                      "system": "JAMISDP01",
                      "code": "2B74000000000000",
                      "display": "外用・塗布・１日４回"
                    }
                  ]
                }
              ]
            },
            "site": {
              "coding": [
                {
                  "system": "JAMISDP01",
                  "code": "77L",
                  "display": "左手"
                }
              ]
            },
            "route": {
              "coding": [
                {
                  "system": "HL70162",
                  "code": "AP",
                  "display": "外用"
                }
              ]
            },
            "doseAndRate": [
              {
                "type": {
                  "coding": [
                    {
                      "system": "LC",
                      "code": "Give Amount - Minimum",
                      "display": "与薬量－最小"
                    }
                  ]
                },
                "doseQuantity": {
                  "value": 0,
                  "code": "\"\""
                }
              }
            ]
          }
        ],
        "dispenseRequest": {
          "quantity": {
            "value": 2,
            "unit": "本",
            "code": "HON"
          }
        },
        "resourceType": "MedicationRequest"
      }
    }
  ],
  "resourceType": "Bundle"
}
```

Test Server (heroku)
```
https://hl7v2-to-fhir.herokuapp.com/api/hl7/fhir_prescription_generators
```