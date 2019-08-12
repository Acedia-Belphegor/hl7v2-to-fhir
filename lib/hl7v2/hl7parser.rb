# encoding: UTF-8
require 'json'
require 'pathname'

class HL7Parser
    def initialize(raw_message = nil)
        # セグメントターミネータ
        @segment_delim = "\r"
        # フィールドセパレータ
        @field_delim = '|'
        # 成分セパレータ
        @element_delim = '^'
        # 反復セパレータ
        @repeat_delim = '~'

        # データ型を定義したJSONファイルを読み込む        
        filename = Pathname.new(File.dirname(File.expand_path(__FILE__))).join('json').join('HL7_DATATYPE.json')
        @hl7_datatypes = File.open(filename) do |io|
            JSON.load(io)
        end

        # セグメントを定義したJSONファイルを読み込む        
        filename = Pathname.new(File.dirname(File.expand_path(__FILE__))).join('json').join('HL7_SEGMENT.json')
        @hl7_segments = open(filename) do |io|
            JSON.load(io)
        end

        # 引数にRawデータが設定されている場合はパースする
        if !raw_message.nil? then
            parse(raw_message)
            @raw_message = raw_message
        end
    end

    # セグメントオブジェクトを返す
    def get_new_segment(id)
        Marshal.load(Marshal.dump(@hl7_segments[id]))
    end

    # データ型オブジェクトを返す
    def get_new_datatype(id)
        Marshal.load(Marshal.dump(@hl7_datatypes[id]))
    end

    # JSONパースされたメッセージを返す
    def get_parsed_message()
        return @parsed_message
    end

    # 指定されたセグメントのリストを返す
    def get_parsed_segments(segment_id)
        return @parsed_message.select{|c| c[0]['value'] == segment_id}
    end

    # 指定されたセグメント、フィールドを返す
    def get_parsed_fields(segment_id, field_name)
        segments = get_parsed_segments(segment_id)
        if !segments.nil? then
            return segments.first.select{|c| c['name'] == field_name}
        end
    end

    # 指定されたセグメント、フィールドの値を返す
    def get_parsed_value(segment_id, field_name)
        segments = get_parsed_segments(segment_id)
        if !segments.nil? then
            field = segments.first.find{|c| c['name'] == field_name}
            if !field.nil? then
                return field['value']
            end
        end
    end

    def get_sending_facility()
        if !@sending_facility.nil? then
            return @sending_facility
        end
        value = get_parsed_value('MSH','Sending Facility')
        if value.length == 10 then
            @sending_facility = {
                all: value,
                state: value[0,2], # 都道府県番号
                point: value[2,1], # 点数表番号
                facility: value[3,7], # 医療機関コード
            }
            return @sending_facility
        end
        return {}
    end

    # HL7メッセージ(Raw Data)をJSON形式にパースする
    def parse(raw_message)
        begin
            # 改行コード(セグメントターミネータ)が「\n」の場合は「\r」に置換する
            raw_message.gsub!("\n", @segment_delim)
            # セグメント分割
            segments = raw_message.split(@segment_delim)
            result = Array[]
        
            segments.each do |segment|
                # メッセージ終端の場合は処理を抜ける
                if /\x1c/.match(segment) then
                    break
                end
                # フィールド分割
                fields = segment.split(@field_delim)
                segment_id = fields[0]
                segment_json = get_new_segment(segment_id)
                segment_idx = 0

                segment_json.each do |field|
                    # MSH-1は強制的にフィールドセパレータをセットする
                    if segment_id == 'MSH' && field['name'] == 'Field Separator' then
                        value = @field_delim
                    else
                        if fields.length > segment_idx then
                            value = fields[segment_idx]
                        else
                            value = ''
                        end
                        segment_idx += 1
                    end
                    # 分割したフィールドの値をvalue要素として追加する
                    field.store('value', value)
                    repeat_fields = Array[]

                    # MSH-2(コード化文字)には反復セパレータ(~)が含まれているので反復フィールド分割処理を行わない
                    if segment_id == 'MSH' && field['name'] == 'Encoding Characters' then
                        repeat_fields = Array[value]
                    else
                        # 反復フィールド分割
                        repeat_fields = value.split(@repeat_delim)
                    end
                    # データ型
                    type_id = field['type']
                    element_jsons = Array[]

                    repeat_fields.each do |repeat_field|
                        # フィールドデータを再帰的にパースする
                        element_value = element_parse(repeat_field, type_id, @element_delim)
                        element_jsons.push(element_value) if !element_value.nil?
                    end
                    # 不要な要素を削除する
                    field.delete('ssmix2-required')
                    field.delete('nho_name')
                    # パースした値を追加する
                    field.store('array_data', element_jsons)
                end                
                result.push(segment_json)
            end
            @parsed_message = result
            return @parsed_message
        rescue => e
            throw e
        end
    end

    private
    def element_parse(raw_data, type_id, delim)
        element_json = get_new_datatype(type_id)
        element_array = raw_data.split(delim)
        element_idx = 0

        if element_json.instance_of?(Array) then
            element_json.each do |element|
                element.delete('nho_name')
                if element_array.length > element_idx then
                    value = element_array[element_idx]
                else
                    value = ''
                end
                element.store('value', value)
                if !value.empty? then
                    array_data = element_parse(value, element['type'], '&')
                    element.store('array_data', array_data)
                end
                element_idx += 1
            end
            return element_json
        end
    end
end

# サンプルメッセージ
def get_message_example(message_code = 'RDE')
    msg = ""
    case message_code
    when 'RDE' then
        # 内服
        msg = msg + "MSH|^~\&|HL7v2|1319999999|HL7FHIR|1319999999|20160821161523||RDE^O11^RDE_O11|201608211615230143|P|2.5||||||~ISOIR87||ISO 2022-1994" + "\r"
        msg = msg + "PID|||1000000001^^^^PI||患者^太郎^^^^^L^I~カンジャ^タロウ^^^^^L^P||19791101|M|||^^渋谷区^東京都^1510071^JPN^H^東京都渋谷区本町三丁目１２ー１||^PRN^PH^^^^^^^^^03-1234-5678" + "\r"
        msg = msg + "IN1|1|06^組合管掌健康保険^JHSD0001|06050116|||||||９２０４５|１０|19990514|||||SEL^本人^HL70063" + "\r"
        msg = msg + "IN1|2|15^障害者総合支援法 更正医療^JHSD0001|15138092|障害者総合支援 更正医療（東京都）" + "\r"
        msg = msg + "ORC|NW|12345678||12345678_01|||||20160825|||123456^医師^春子^^^^^^^L^^^^^I~^イシ^ハルコ^^^^^^^L^^^^^P|||||01^内科^99Z01||||メドレークリニック|^^港区^東京都^^JPN^^東京都港区六本木３−２−１|||||||O^外来患者オーダ^HL70482" + "\r"
        msg = msg + "RXE||103835401^ムコダイン錠２５０ｍｇ^HOT|1||TAB^錠^MR9P|TAB^錠^MR9P|01^１回目から服用^JHSP0005|||9|TAB^錠^MR9P||||||||3^TAB&錠&MR9P||OHP^外来処方^MR9P~OHI^院内処方^MR9P||||||21^内服^JHSP0003" + "\r"
        msg = msg + "TQ1|||1013044400000000&内服・経口・１日３回朝昼夕食後&JAMISDP01|||3^D&日&ISO+|20160825" + "\r"
        msg = msg + "RXR|PO^口^HL70162" + "\r"
        msg = msg + "ORC|NW|12345678||12345678_01|||||20160825|||123456^医師^春子^^^^^^^L^^^^^I~^イシ^ハルコ^^^^^^^L^^^^^P|||||01^内科^99Z01||||メドレークリニック|^^港区^東京都^^JPN^^東京都港区六本木３−２−１|||||||O^外来患者オーダ^HL70482" + "\r"
        msg = msg + "RXE||110626901^パンスポリンＴ錠１００ １００ｍｇ^HOT|2||TAB^錠^MR9P|TAB^錠^MR9P|01^１回目から服用^JHSP0005|||18|TAB^錠^MR9P||||||||6^TAB&錠&MR9P||OHP^外来処方^MR9P~OHI^院内処方^MR9P||||||21^内服^JHSP0003" + "\r"
        msg = msg + "TQ1|||1013044400000000&内服・経口・１日３回朝昼夕食後&JAMISDP01|||3^D&日&ISO+|20160825" + "\r"
        msg = msg + "RXR|PO^口^HL70162" + "\r"
        # 頓服
        msg = msg + "ORC|NW|12345678||12345678_02|||||20160825|||123456^医師^春子^^^^^^^L^^^^^I~^イシ^ハルコ^^^^^^^L^^^^^P|||||01^内科^99Z01||||メドレークリニック|^^港区^東京都^^JPN^^東京都港区六本木３−２−１|||||||O^外来患者オーダ^HL70482" + "\r"
        msg = msg + "RXE||100795402^ボルタレン錠２５ｍｇ^HOT|1||TAB^錠^MR9P|||||10|TAB^錠^MR9P||||||||||OHP^外来処方^MR9P~OHI^院内処方^MR9P||||||22^頓用^JHSP0003" + "\r"
        msg = msg + "TQ1|||1050110020000000&内服・経口・疼痛時&JAMISDP01||||20160825||||1 日2 回まで|||10" + "\r"
        msg = msg + "RXR|PO^口^HL70162" + "\r"
        # 外用
        msg = msg + "ORC|NW|12345678||12345678_03|||||20160825|||123456^医師^春子^^^^^^^L^^^^^I~^イシ^ハルコ^^^^^^^L^^^^^P|||||01^内科^99Z01||||メドレークリニック|^^港区^東京都^^JPN^^東京都港区六本木３−２−１|||||||O^外来患者オーダ^HL70482" + "\r"
        msg = msg + "RXE||106238001^ジフラール軟膏０．０５％^HOT|""||""|OIT^軟膏^MR9P||||2|HON^本^MR9P||||||||||OHP^外来処方^MR9P~OHO^院外処方^MR9P||||||23^外用^JHSP0003" + "\r"
        msg = msg + "TQ1|||2B74000000000000&外用・塗布・１日４回&JAMISDP01||||20160825" + "\r"
        msg = msg + "RXR|AP^外用^HL70162|77L^左手^JAMISDP01" + "\r"
    when 'OUL' then
        msg = msg + "MSH|^~\&|DOCX|HIS|GW|GW|20111024181046.736||OUL^R22^OUL_R22|20111024000001|P|2.5||||||~ISO IR87||ISO 2022-1994" + "\r"
        msg = msg + "PID|0001||1014360||駿河^葵^^^^^L^I~スルガ^アオイ^^^^^L^P||19520717|F|||^^^^422-8033^JPN^H^静岡県静岡市登呂２９４−１３||^PRN^PH^^^^^^^^^054-000-0000|||||||||||||||||||20030205115729" + "\r"
        msg = msg + "PV1|0001|O|2^^^^^C||||ishi01^テスト^医師^^^^^^^L^^^^^I|||002" + "\r"
        msg = msg + "SPM|0001|||023^血清^JC10^01^血清^99XYZ" + "\r"
        msg = msg + "ORC|SC|000000002928810|||||||20111024000000|ishi01^テスト^医師^^^^^^^L^^^^^I||ishi01^テスト^医師^^^^^^^L^^^^^I|2^^^^^C||||002^内科^99XY1|Fu^^99XY2|||追手町病院|^^^^422-0000^JPN^^静岡市駿河区追手町1-1|^^^^^^^^^^^054-252-1400||||||O^外来患者^HL70482" + "\r"
        msg = msg + "OBR|0001|000000002928810|000000002928810|1^生化学^99XYZ|||20111024|20111024||||||||ishi01^テスト^医師^^^^^^^L^^^^^I||||||20111024160328" + "\r"
        msg = msg + "OBX|0005|NM|3B035000002327201^GOT(AST)^JC10^10207^GOT(AST)^99LAB||14|IU/L^IU/L^99UNT|8-38||||F|||20111024000000" + "\r"
        msg = msg + "OBX|0006|NM|3B045000002327201^GPT(ALT)^JC10^10208^GPT(ALT)^99LAB||9|IU/L^IU/L^99UNT|4-43||||F|||20111024000000" + "\r"
        msg = msg + "OBX|0008|NM|3B070000002327101^ＡＬＰ^JC10^10209^ＡＬＰ^99LAB||147|IU/L^IU/L^99UNT|110-354||||F|||20111024000000" + "\r"
        msg = msg + "OBX|0007|NM|3B050000002327201^ＬＤＨ^JC10^10206^ＬＤＨ^99LAB||139|IU/L^IU/L^99UNT|121-245||||F|||20111024000000" + "\r"
        msg = msg + "OBX|0004|NM|3J010000002327101^Ｔ−Ｂｉｌ^JC10^10213^Ｔ−Ｂｉｌ^99LAB||0.7|mg/dl^mg/dl^99UNT|0.2-1.2||||F|||20111024000000" + "\r"
        msg = msg + "OBX|0010|NM|3C025000002327201^Ｕｒｅａ−Ｎ^JC10^10215^Ｕｒｅａ−Ｎ^99LAB||12|mg/dl^mg/dl^99UNT|8-22||||F|||20111024000000" + "\r"
        msg = msg + "OBX|0011|NM|3C015000002327101^Ｃｒｅ^JC10^10216^Ｃｒｅ^99LAB||0.53|mg/dl^mg/dl^99UNT|0.47-0.79||||F|||20111024000000" + "\r"
        msg = msg + "OBX|0009|NM|3F050000002327101^Ｔ−ＣＨＯ^JC10^10201^Ｔ−ＣＨＯ^99LAB||175|mg/dl^mg/dl^99UNT|120-220||||F|||20111024000000" + "\r"
        msg = msg + "OBX|0016|NM|3H030000002327101^Ｃａ^JC10^10218^Ｃａ^99LAB||8.5|mg/dl^mg/dl^99UNT|8.0-10.2||||F|||20111024000000" + "\r"
        msg = msg + "OBX|0018|NM|5C070000002306201^ＣＲＰ^JC10^10221^ＣＲＰ^99LAB||2.0|mg/dl^mg/dl^99UNT|0.0-0.5||||F|||20111024000000" + "\r"
        msg = msg + "OBX|0001|NM|3A010000002327101^ＴＰ^JC10^10222^ＴＰ^99LAB||5.8|g/dl^g/dl^99UNT|6.5-8.2||||F|||20111024000000" + "\r"
        msg = msg + "OBX|0013|NM|3H010000002326101^Ｎａ^JC10^10240^Ｎａ^99LAB||140|mEq/L^mEq/L^99UNT|130-148||||F|||20111024000000" + "\r"
        msg = msg + "OBX|0015|NM|3H015000002326101^Ｋ^JC10^10241^Ｋ^99LAB||4.0|mEq/L^mEq/L^99UNT|3.6-5.0||||F|||20111024000000" + "\r"
        msg = msg + "OBX|0014|NM|3H020000002326101^Ｃｌ^JC10^10242^Ｃｌ^99LAB||104|mEq/L^mEq/L^99UNT|98-110||||F|||20111024000000" + "\r"
        msg = msg + "SPM|0002|||019^血液^JC10^02^血液^99XYZ" + "\r"
        msg = msg + "ORC|SC|000000002928810|||||||20111024000000|ishi01^テスト^医師^^^^^^^L^^^^^I||ishi01^テスト^医師^^^^^^^L^^^^^I|2^^^^^C||||002^内科^99XY1|Fu^^99XY2|||追手町病院|^^^^422-0000^JPN^^静岡市駿河区追手町1-1|^^^^^^^^^^^054-252-1400||||||O^外来患者^HL70482" + "\r"
        msg = msg + "OBR|0001|000000002928810|000000002928810|3^血液^99XYZ|||20111024|20111024||||||||ishi01^テスト^医師^^^^^^^L^^^^^I||||||20111024160328" + "\r"
        msg = msg + "OBX|0002|NM|2A020000001930101^ＲＢＣ^JC10^30004^ＲＢＣ^99LAB||397|*10＾4/ul^*10＾4/ul^99UNT|376-500||||F|||20111024000000" + "\r"
        msg = msg + "OBX|0003|NM|2A030000001928201^ＨＧＢ^JC10^30005^ＨＧＢ^99LAB||12.8|g/dl^g/dl^99UNT|11.3-15.2|L|||F|||20111024000000" + "\r"
        msg = msg + "OBX|0001|NM|2A010000001930101^ＷＢＣ^JC10^30002^ＷＢＣ^99LAB||7.1|*10＾3/ul^*10＾3/ul^99UNT|3.5-9.5||||F|||20111024000000" + "\r"
        msg = msg + "OBX|0001|NM|2A040000001930202^ＨＴ^JC10^30006^ＨＴ^99LAB||37.9|%^%^99UNT|33.0-45.0||||F|||20111024000000" + "\r"
        msg = msg + "OBX|0005|NM|2A060000001930102^ＭＣＶ^JC10^30007^ＭＣＶ^99LAB||95.3|nm＾3^nm＾3^99UNT|79-100||||F|||20111024000000" + "\r"
        msg = msg + "OBX|0006|NM|2A070000001930102^ＭＣＨ^JC10^30008^ＭＣＨ^99LAB||32.2|pg^pg^99UNT|27-34||||F|||20111024000000" + "\r"
        msg = msg + "OBX|0007|NM|2A080000001930102^ＭＣＨＣ^JC10^30009^ＭＣＨＣ^99LAB||33.7|%^%^99UNT|30-35||||F|||20111024000000" + "\r"
    end
    return msg
end