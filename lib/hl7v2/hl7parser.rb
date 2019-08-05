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

    def get_parsed_fields(segment_id, field_name)
        segments = get_parsed_segments(segment_id)
        if !segments.nil? then
            return segments.first.select{|c| c['name'] == field_name}
        end
    end

    def get_parsed_value(segment_id, field_name)
        segments = get_parsed_segments(segment_id)
        if !segments.nil? then
            field = segments.first.find{|c| c['name'] == field_name}
            if !field.nil? then
                return field['value']
            end
        end
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

def get_message_example()
    msg = ""
    # msg = msg + "MSH|^~\&|HL7v2|1319999999|HL7FHIR|1319999999|20160821161523||RDE^O11^RDE_O11|201608211615230143|P|2.5||||||~ISOIR87||ISO 2022-1994" + "\r"
    # msg = msg + "PID|||1000000001^^^^PI||患者^太郎^^^^^L^I~カンジャ^タロウ^^^^^L^P||19601224|M" + "\r"
    # msg = msg + "IN1|1|06^組合管掌健康保険^JHSD0001|06050116|||||||９２０４５|１０|19990514|||||SEL^本人^HL70063" + "\r"
    # msg = msg + "IN1|2|15^障害者総合支援法 更正医療^JHSD0001|15138092|障害者総合支援 更正医療（東京都）" + "\r"
    # msg = msg + "ORC|NW|12345678||12345678_01|||||20160825|||123456^医師^春子^^^^^^^L^^^^^I~^イシ^ハルコ^^^^^^^L^^^^^P|||||01^内科^99Z01||||メドレークリニック|^^港区^東京都^^JPN^^東京都港区六本木３−２−１|||||||O^外来患者オーダ^HL70482" + "\r"
    # msg = msg + "RXE||103835401^ムコダイン錠２５０ｍｇ^HOT|1||TAB^錠^MR9P||01^１回目から服用^JHSP0005|||9|TAB^錠^MR9P||||||||3^TAB&錠&MR9P||OHP^外来処方^MR9P~OHI^院内処方^MR9P||||||21^内服^JHSP0003" + "\r"
    # msg = msg + "TQ1|||1013044400000000&内服・経口・１日３回朝昼夕食後&JAMISDP01|||3^D&日&ISO+|20160825" + "\r"
    # msg = msg + "RXR|PO^口^HL70162" + "\r"
    # msg = msg + "ORC|NW|12345678||12345678_01|||||20160825|||123456^医師^春子^^^^^^^L^^^^^I~^イシ^ハルコ^^^^^^^L^^^^^P|||||01^内科^99Z01||||メドレークリニック|^^港区^東京都^^JPN^^東京都港区六本木３−２−１|||||||O^外来患者オーダ^HL70482" + "\r"
    # msg = msg + "RXE||110626901^パンスポリンＴ錠１００ １００ｍｇ^HOT|2||TAB^錠^MR9P|| 01^１回目から服用^JHSP0005|||18|TAB^錠^MR9P||||||||6^TAB&錠&MR9P||OHP^外来処方^MR9P~OHI^院内処方^MR9P||||||21^内服^JHSP0003" + "\r"
    # msg = msg + "TQ1|||1013044400000000&内服・経口・１日３回朝昼夕食後&JAMISDP01|||3^D&日&ISO+|20160825" + "\r"
    # msg = msg + "RXR|PO^口^HL70162" + "\r"
    # msg = msg + "ORC|NW|12345678||12345678_02|||||20160825|||123456^医師^春子^^^^^^^L^^^^^I~^イシ^ハルコ^^^^^^^L^^^^^P|||||01^内科^99Z01||||メドレークリニック|^^港区^東京都^^JPN^^東京都港区六本木３−２−１|||||||O^外来患者オーダ^HL70482" + "\r"
    # msg = msg + "RXE||100607002^アレビアチン散１０％^HOT|50||MG^ミリグラム^MR9P|PWD^散剤^MR9P|01^１回目から服用^JHSP0005|||1.4|G^グラム^MR9P||||||||100^MG&ミリグラム&MR9P||OHP^外来処方^MR9P~OHI^院内処方^MR9P||||100|MG^ミリグラム^MR9P|21^内服^JHSP0003" + "\r"
    # msg = msg + "TQ1|||1012040400000000&内服・経口・１日２回朝夕食後&JAMISDP01|||14^D&日&ISO+|20160825" + "\r"
    # msg = msg + "RXR|PO^口^HL70162" + "\r"
    # msg = msg + "ORC|NW|12345678||12345678_02|||||20160825|||123456^医師^春子^^^^^^^L^^^^^I~^イシ^ハルコ^^^^^^^L^^^^^P|||||01^内科^99Z01||||メドレークリニック|^^港区^東京都^^JPN^^東京都港区六本木３−２−１|||||||O^外来患者オーダ^HL70482" + "\r"
    # msg = msg + "RXE||100565315^フェノバルビタール散１０％「ホエイ」^HOT|50||MG^ミリグラム^MR9P|PWD^散剤^MR9P|01^１回目から服用^JHSP0005|||1.4|G^グラム^MR9P||||||||100^MG&ミリグラム&MR9P||OHP^外来処方^MR9P~OHI^院内処方^MR9P||||100|MG^ミリグラム^MR9P|21^内服^JHSP0003" + "\r"
    # msg = msg + "TQ1|||1012040400000000&内服・経口・１日２回朝夕食後&JAMISDP01|||14^D&日&ISO+|20160825" + "\r"
    # msg = msg + "RXR|PO^口^HL70162" + "\r"

    # 内服
    msg = msg + "MSH|^~\&|HL7v2|1319999999|HL7FHIR|1319999999|20160821161523||RDE^O11^RDE_O11|201608211615230143|P|2.5||||||~ISOIR87||ISO 2022-1994" + "\r"
    msg = msg + "PID|||1000000001^^^^PI||患者^太郎^^^^^L^I~カンジャ^タロウ^^^^^L^P||19601224|M" + "\r"
    msg = msg + "IN1|1|06^組合管掌健康保険^JHSD0001|06050116|||||||９２０４５|１０|19990514|||||SEL^本人^HL70063" + "\r"
    msg = msg + "IN1|2|15^障害者総合支援法 更正医療^JHSD0001|15138092|障害者総合支援 更正医療（東京都）" + "\r"
    msg = msg + "ORC|NW|12345678||12345678_01|||||20160825|||123456^医師^春子^^^^^^^L^^^^^I~^イシ^ハルコ^^^^^^^L^^^^^P|||||01^内科^99Z01||||メドレークリニック|^^港区^東京都^^JPN^^東京都港区六本木３−２−１|||||||O^外来患者オーダ^HL70482" + "\r"
    msg = msg + "RXE||103835401^ムコダイン錠２５０ｍｇ^HOT|1||TAB^錠^MR9P|TAB^錠^MR9P|01^１回目から服用^JHSP0005|||9|TAB^錠^MR9P||||||||3^TAB&錠&MR9P||OHP^外来処方^MR9P~OHI^院内処方^MR9P||||||21^内服^JHSP0003" + "\r"
    msg = msg + "TQ1|||1013044400000000&内服・経口・１日３回朝昼夕食後&JAMISDP01|||3^D&日&ISO+|20160825" + "\r"
    msg = msg + "RXR|PO^口^HL70162" + "\r"
    msg = msg + "ORC|NW|12345678||12345678_01|||||20160825|||123456^医師^春子^^^^^^^L^^^^^I~^イシ^ハルコ^^^^^^^L^^^^^P|||||01^内科^99Z01||||メドレークリニック|^^港区^東京都^^JPN^^東京都港区六本木３−２−１|||||||O^外来患者オーダ^HL70482" + "\r"
    msg = msg + "RXE||110626901^パンスポリンＴ錠１００ １００ｍｇ^HOT|2||TAB^錠^MR9P|TAB^錠^MR9P| 01^１回目から服用^JHSP0005|||18|TAB^錠^MR9P||||||||6^TAB&錠&MR9P||OHP^外来処方^MR9P~OHI^院内処方^MR9P||||||21^内服^JHSP0003" + "\r"
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

    return msg
end

parser = HL7Parser.new(get_message_example)
puts parser.get_parsed_message()