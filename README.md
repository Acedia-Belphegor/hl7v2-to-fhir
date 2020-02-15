# HL7v2 to FHIR Conversion API

## fhir_prescription_generators

  | Contents | Description |
  | :--- | :--- |
  | 概要 | HL7v2処方オーダーメッセージをFHIRリソースに変換するAPI |
  | URI | `POST` /api/hl7/fhir_prescription_generators.json (.xml) |
  | Encoding | UTF-8 |
  | Request | HL7v2メッセージ(RDE^O11) |
  | Response | FHIRリソース(JSON/XML) |

## notes
  - request-bodyのHL7v2メッセージに`<EOM>(0x1C,0x0D)`は設定しない

## mapping

### MSH
| v2 field | v2 name | FHIR resource | FHIR element | memo |
| :---: | :--- | :--- | :--- | :--- |
| 1 | Field Separator |  |  |  |
| 2 | Encoding Characters |  |  |  |
| 3 | Sending Application | MessageHeader | source.name |  |
| 4 | Sending Facility |  |  |  |
| 5 | Receiving Application | MessageHeader | destination.name |  |
| 6 | Receiving Facility |  |  |  |
| 7 | Date/Time Of Message |  |  |  |
| 8 | Security |  |  |  |
| 9 | Message Type | MessageHeader | eventCoding |  |
| 10 | Message Control ID |  |  |  |
| 11 | Processing ID |  |  |  |
| 12 | Version ID |  |  |  |
| 13 | Sequence Number |  |  |  |
| 14 | Continuation Pointer |  |  |  |
| 15 | Accept Acknowledgment Type |  |  |  |
| 16 | Application Acknowledgment Type |  |  |  |
| 17 | Country Code |  |  |  |
| 18 | Character Set |  |  |  |
| 19 | Principal Language Of Message |  |  |  |
| 20 | Alternate Character Set Handling Scheme |  |  |  |
| 21 | Message Profile Identifier |  |  |  |

### PID
| v2 field | v2 name | FHIR resource | FHIR element | memo |
| :---: | :--- | :--- | :--- | :--- |
| 1 | Set ID - PID |  |  |  |
| 2 | Patient ID |  |  |  |
| 3 | Patient Identifier List | Patient | identifier |
| 4 | Alternate Patient ID - PID |  |  |  |
| 5 | Patient Name | Patient | name |
| 6 | Mother’s Maiden Name |  |  |  |
| 7 | Date/Time of Birth | Patient | birthDate |
| 8 | Administrative Sex | Patient | gender |
| 9 | Patient Alias |  |  |  |
| 10 | Race |  |  |  |
| 11 | Patient Address | Patient | address |
| 12 | County Code |  |  |  |
| 13 | Phone Number - Home | Patient | telecom |
| 14 | Phone Number - Business | Patient | telecom |
| 15 | Primary Language | Patient | communication.language |
| 16 | Marital Status | Patient | maritalStatus |
| 17 | Religion |  |  |  |
| 18 | Patient Account Number |  |  |  |
| 19 | SSN Number - Patient |  |  |  |
| 20 | Driver's License Number - Patient |  |  |  |
| 21 | Mother's Identifier |  |  |  |
| 22 | Ethnic Group |  |  |  |
| 23 | Birth Place |  |  |  |
| 24 | Multiple Birth Indicator | Patient | multipleBirthBoolean |
| 25 | Birth Order | Patient | multipleBirthInteger |
| 26 | Citizenship |  |  |  |
| 27 | Veterans Military Status |  |  |  |
| 28 | Nationality |  |  |  |
| 29 | Patient Death Date and Time | Patient | deceasedDateTime |
| 30 | Patient Death Indicator | Patient | deceasedBoolean |
| 31 | Identity Unknown Indicator |  |  |  |
| 32 | Identity Reliability Code |  |  |  |
| 33 | Last Update Date/Time |  |  |  |
| 34 | Last Update Facility |  |  |  |
| 35 | Species Code |  |  |  |
| 36 | Breed Code |  |  |  |
| 37 | Strain |  |  |  |
| 38 | Production Class Code |  |  |  |
| 39 | Tribal Citizenship |  |  |  |

### IN1
| v2 field | v2 name | FHIR resource | FHIR element | memo |
| :---: | :--- | :--- | :--- | :--- |
| 1 | Set ID - IN1 |  |  |  |
| 2 | Insurance Plan ID | Coverage | type |
| 3 | Insurance Company ID | Coverage | identifier |
| 4 | Insurance Company Name |  |  |  |
| 5 | Insurance Company Address |  |  |  |
| 6 | Insurance Co Contact Person |  |  |  |
| 7 | Insurance Co Phone Number |  |  |  |
| 8 | Group Number |  |  |  |
| 9 | Group Name |  |  |  |
| 10 | Insured’s Group Emp ID | Coverage | identifier |
| 11 | Insured’s Group Emp Name | Coverage | identifier |
| 12 | Plan Effective Date | Coverage | period.start |
| 13 | Plan Expiration Date | Coverage | period.end |
| 14 | Authorization Information |  |  |  |
| 15 | Plan Type |  |  |  |
| 16 | Name Of Insured |  |  |  |
| 17 | Insured’s Relationship To Patient | Coverage | relationship |
| 18 | Insured’s Date Of Birth |  |  |  |
| 19 | Insured’s Address |  |  |  |
| 20 | Assignment Of Benefits |  |  |  |
| 21 | Coordination Of Benefits |  |  |  |
| 22 | Coord Of Ben. Priority |  |  |  |
| 23 | Notice Of Admission Flag |  |  |  |
| 24 | Notice Of Admission Date |  |  |  |
| 25 | Report Of Eligibility Flag |  |  |  |
| 26 | Report Of Eligibility Date |  |  |  |
| 27 | Release Information Code |  |  |  |
| 28 | Pre-Admit Cert (PAC) |  |  |  |
| 29 | Verification Date/Time |  |  |  |
| 30 | Verification By |  |  |  |
| 31 | Type Of Agreement Code |  |  |  |
| 32 | Billing Status |  |  |  |
| 33 | Lifetime Reserve Days |  |  |  |
| 34 | Delay Before L.R. Day |  |  |  |
| 35 | Company Plan Code |  |  |  |
| 36 | Policy Number |  |  |  |
| 37 | Policy Deductible |  |  |  |
| 38 | Policy Limit - Amount |  |  |  |
| 39 | Policy Limit - Days |  |  |  |
| 40 | Room Rate - Semi-Private |  |  |  |
| 41 | Room Rate - Private |  |  |  |
| 42 | Insured’s Employment Status |  |  |  |
| 43 | Insured’s Administrative Sex |  |  |  |
| 44 | Insured’s Employer’s Address |  |  |  |
| 45 | Verification Status |  |  |  |
| 46 | Prior Insurance Plan ID |  |  |  |
| 47 | Coverage Type |  |  |  |
| 48 | Handicap |  |  |  |
| 49 | Insured’s ID Number |  |  |  |
| 50 | Signature Code |  |  |  |
| 51 | Signature Code Date |  |  |  |
| 52 | Insured’s Birth Place |  |  |  |
| 53 | VIP Indicator |  |  |  |

### ORC
| v2 field | v2 name | FHIR resource | FHIR element | memo |
| :---: | :--- | :--- | :--- | :--- |
| 1 | Order Control |  |  |  |
| 2 | Placer Order Number | MedicationRequest | identifier |
| 3 | Filler Order Number |  |  |  |
| 4 | Placer Group Number | MedicationRequest | identifier |
| 5 | Order Status |  |  |  |
| 6 | Response Flag |  |  |  |
| 7 | Quantity/Timing |  |  |  |
| 8 | Parent |  |  |  |
| 9 | Date/Time of Transaction | MedicationRequest | authoredOn |
| 10 | Entered By |  |  |  |
| 11 | Verified By |  |  |  |
| 12 | Ordering Provider | Practitioner | name | (ref:MedicationRequest.requester)
| 13 | Enterer's Location |  |  |  |
| 14 | Call Back Phone Number |  |  |  |
| 15 | Order Effective Date/Time |  |  |  |
| 16 | Order Control Code Reason |  |  |  |
| 17 | Entering Organization | PractitionerRole | specialty |
| 18 | Entering Device |  |  |  |
| 19 | Action By |  |  |  |
| 20 | Advanced Beneficiary Notice Code |  |  |  |
| 21 | Ordering Facility Name | Organization | name |
| 22 | Ordering Facility Address | Organization | address |
| 23 | Ordering Facility Phone Number | Organization | telecom |
| 24 | Ordering Provider Address |  |  |  |
| 25 | Order Status Modifier |  |  |  |
| 26 | Advanced Beneficiary Notice Override Reason |  |  |  |
| 27 | Filler's Expected Availability Date/Time |  |  |  |
| 28 | Confidentiality Code |  |  |  |
| 29 | Order Type | MedicationRequest | category |  |
| 30 | Enterer Authorization Mode |  |  |  |

### RXE
| v2 field | v2 name | FHIR resource | FHIR element | memo |
| :---: | :--- | :--- | :--- | :--- |
| 1 | Quantity/Timing |  |  |  |
| 2 | Give Code | MedicationRequest | medicationCodeableConcept |
| 3 | Give Amount - Minimum | MedicationRequest | dosageInstruction.dosage.doseAndRate.doseQuantity |
| 4 | Give Amount - Maximum | MedicationRequest | dosageInstruction.dosage.doseAndRate.doseQuantity |
| 5 | Give Units | MedicationRequest | dosageInstruction.dosage.doseAndRate.ddoseQuantity |
| 6 | Give Dosage Form | MedicationRequest | category |
| 7 | Provider's Administration Instructions | MedicationRequest | dosageInstruction.dosage.additionalInstruction |
| 8 | Deliver-to Location |  |  |  |
| 9 | Substitution Status |  |  |  |
| 10 | Dispense Amount | MedicationRequest | dispenseRequest.quantity |
| 11 | Dispense Units | MedicationRequest | dispenseRequest.quantity |
| 12 | Number of Refills |  |  |  |
| 13 | Ordering Provider's DEA Number | Practitioner | qualification.identifier |  |
| 14 | Pharmacist/Treatment Supplier's Verifier ID |  |  |  |
| 15 | Prescription Number | MedicationRequest | identifier |
| 16 | Number of Refills Remaining |  |  |  |
| 17 | Number of Refills/Doses Dispensed |  |  |  |
| 18 | D/T of Most Recent Refill or Dose Dispensed |  |  |  |
| 19 | Total Daily Dose | MedicationRequest | dosageInstruction.dosage.extension |
| 20 | Needs Human Review |  |  |  |
| 21 | Pharmacy/Treatment Supplier's Special Dispensing Instructions | MedicationRequest | category |  |
| 22 | Give Per (Time Unit) |  |  |  |
| 23 | Give Rate Amount |  |  |  |
| 24 | Give Rate Units |  |  |  |
| 25 | Give Strength |  |  |  |
| 26 | Give Strength Units |  |  |  |
| 27 | Give Indication | MedicationRequest | category |
| 28 | Dispense Package Size |  |  |  |
| 29 | Dispense Package Size Unit |  |  |  |
| 30 | Dispense Package Method |  |  |  |
| 31 | Supplementary Code |  |  |  |
| 32 | Original Order Date/Time |  |  |  |
| 33 | Give Drug Strength Volume |  |  |  |
| 34 | Give Drug Strength Volume Units |  |  |  |
| 35 | Controlled Substance Schedule |  |  |  |
| 36 | Formulary Status |  |  |  |
| 37 | Pharmaceutical Substance Alternative |  |  |  |
| 38 | Pharmacy of Most Recent Fill |  |  |  |
| 39 | Initial Dispense Amount |  |  |  |
| 40 | Dispensing Pharmacy |  |  |  |
| 41 | Dispensing Pharmacy Address |  |  |  |
| 42 | Deliver-to Patient Location |  |  |  |
| 43 | Deliver-to Address |  |  |  |
| 44 | Pharmacy Order Type |  |  |  |

### TQ1
| v2 field | v2 name | FHIR resource | FHIR element | memo |
| :---: | :--- | :--- | :--- | :--- |
| 1 | Set ID - TQ1 |  |  |  |
| 2 | Quantity |  |  |  |
| 3 | Repeat Pattern | MedicationRequest | dosageInstruction.dosage.timing.code |
| 4 | Explicit Time |  |  |  |
| 5 | Relative Time and Units |  |  |  |
| 6 | Service Duration | MedicationRequest | dosageInstruction.dosage.timing.repeat |
| 7 | Start date/time | MedicationRequest | dosageInstruction.dosage.timing.event |
| 8 | End date/time |  |  |  |
| 9 | Priority |  |  |  |
| 10 | Condition text |  |  |  |
| 11 | Text instruction | MedicationRequest | dosageInstruction.dosage.patientInstruction |
| 12 | Conjunction |  |  |  |
| 13 | Occurrence duration |  |  |  |
| 14 | Total occurrence's | MedicationRequest | dosageInstruction.dosage.timing.repeat |  |

### RXR
| v2 field | v2 name | FHIR resource | FHIR element | memo |
| :---: | :--- | :--- | :--- | :--- |
| 1 | Route | MedicationRequest | dosageInstruction.dosage.route |
| 2 | Administration Site | MedicationRequest | dosageInstruction.dosage.site |
| 3 | Administration Device |  |  |  |
| 4 | Administration Method |  |  |  |
| 5 | Routing Instruction |  |  |  |
| 6 | Administration Site Modifier |  |  |  |

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