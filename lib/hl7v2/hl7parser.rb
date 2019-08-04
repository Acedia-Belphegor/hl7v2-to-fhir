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
    msg = msg + "MSH|^~\&|e-prescription|1319999999|GW|RECEIVE|20161028130612.5087||RDE^O11^RDE_O11|20161028000000000439|P|2.5||||||~ISO IR87||ISO 2022-1994|SS-MIX2_1.20^SS-MIX2^1.2.392.200250.2.1.100.1.2.120^ISO" + "\r"
    msg = msg + "PID|0001||99990010||患者^一郎^^^^^L^I~カンジャ^イチロウ^^^^^L^P||19791101|M|||^^渋谷区^東京都^1510071^JPN^H^本町三丁目||^PRN^PH^^^^^^^^^03-1234-5678||||||||||||||||||||||||||" + "\r"
    msg = msg + "IN1|1|06^組合管掌健康保険^JHSD0001|06050116|||||||９２０４５|１０|19990514|||||SEL^本人^HL70063" + "\r"
    msg = msg + "IN1|2|15^障害者総合支援法 更正医療^JHSD0001|15138092|障害者総合支援 更正医療（東京都）" + "\r"
    msg = msg + "PV1|0001|O|01^^^^^C||||||||||||||||||||||||||||||||||||||||||" + "\r"
    msg = msg + "ORC|NW|000000000001152||1|||||20161028130607|D100^電子^太郎^^^^^^^L^^^^^I||D100^電子^太郎^^^^^^^L^^^^^I|01^^^^^C||20161028083000||01^内科^HL70069^01^内科^99zzz|SHIENBU-PC2843^^99zzz|||テスト病院|^^^^^JPN^^東京都渋谷区本町x-y-z|^^^^^^^^^^^03-123-4567||||||O^外来患者オーダ^HL70482|" + "\r"
    msg = msg + "RXE||222249^(後)バイアスピリン錠 １００ｍｇ^99zzz|1||TAB^錠^MR9P^T^錠^99zzz|TAB^錠剤^MR9P^01^錠・カプセル^99zzz|3^薬剤情報提供文書発行^JHSP0001~D^粉砕指示^JHSP0002|||28|TAB^錠^MR9P^T^錠^99zzz||???????||8070||||2||^^PRESMEDICINECOMMENT|||||||||||||||||||||01^^^^^C||" + "\r"
    msg = msg + "TQ1|1||12N13&1日2回 朝・夕食後&99zzz|||14^日分|2016102808|2016111000||||||" + "\r"
    msg = msg + "RXR|PO^口^HL70162|||||" + "\r"
    msg = msg + "ORC|NW|000000000001152||1|||||20161028130607|D100^電子^太郎^^^^^^^L^^^^^I||D100^電子^太郎^^^^^^^L^^^^^I|01^^^^^C||20161028083000||01^内科^HL70069^01^内科^99zzz|SHIENBU-PC2843^^99zzz|||テスト病院|^^^^^JPN^^東京都渋谷区本町x-y-z|^^^^^^^^^^^03-123-4567||||||O^外来患者オーダ^HL70482|" + "\r"
    msg = msg + "RXE||215709^テルネリン錠 １ｍｇ^99zzz|1||TAB^錠^MR9P^T^錠^99zzz|TAB^錠剤^MR9P^01^錠・カプセル^99zzz|^^PRESMEDICINECOMMENT|||28|TAB^錠^MR9P^T^錠^99zzz||???????||8070||||2||^^PRESMEDICINECOMMENT|||||||||||||||||||||01^^^^^C||" + "\r"
    msg = msg + "TQ1|1||12N13&1日2回 朝・夕食後&99zzz|||14^日分|2016102808|2016111000||||||" + "\r"
    msg = msg + "RXR|PO^口^HL70162|||||" + "\r"
    msg = msg + "ORC|NW|000000000001152||1|||||20161028130607|D100^電子^太郎^^^^^^^L^^^^^I||D100^電子^太郎^^^^^^^L^^^^^I|01^^^^^C||20161028083000||01^内科^HL70069^01^内科^99zzz|SHIENBU-PC2843^^99zzz|||テスト病院|^^^^^JPN^^東京都渋谷区本町x-y-z|^^^^^^^^^^^03-123-4567||||||O^外来患者オーダ^HL70482|" + "\r"
    msg = msg + "RXE||218976^ムコスタ錠 １００ｍｇ^99zzz|1||TAB^錠^MR9P^T^錠^99zzz|TAB^錠剤^MR9P^01^錠・カプセル^99zzz|^^PRESMEDICINECOMMENT|||28|TAB^錠^MR9P^T^錠^99zzz||???????||8070||||2||^^PRESMEDICINECOMMENT|||||||||||||||||||||01^^^^^C||" + "\r"
    msg = msg + "TQ1|1||12N13&1日2回 朝・夕食後&99zzz|||14^日分|2016102808|2016111000||||||" + "\r"
    msg = msg + "RXR|PO^口^HL70162|||||" + "\r"
    msg = msg + "ORC|NW|000000000001152||2|||||20161028130607|D100^電子^太郎^^^^^^^L^^^^^I||D100^電子^太郎^^^^^^^L^^^^^I|01^^^^^C||20161028083000||01^内科^HL70069^01^内科^99zzz|SHIENBU-PC2843^^99zzz|||テスト病院|^^^^^JPN^^東京都渋谷区本町x-y-z|^^^^^^^^^^^03-123-4567||||||O^外来患者オーダ^HL70482|" + "\r"
    msg = msg + "RXE||215282^チラーヂンＳ錠 ５０μｇ^99zzz|2||TAB^錠^MR9P^T^錠^99zzz|TAB^錠剤^MR9P^01^錠・カプセル^99zzz|^^PRESMEDICINECOMMENT|||28|TAB^錠^MR9P^T^錠^99zzz||???????||8070||||2||^^PRESMEDICINECOMMENT|||||||||||||||||||||01^^^^^C||" + "\r"
    msg = msg + "TQ1|1||11N1&1日1回 朝食後&99zzz|||14^日分|2016102808|2016111000||||||" + "\r"
    msg = msg + "RXR|PO^口^HL70162|||||" + "\r"
    msg = msg + "ORC|NW|000000000001152||2|||||20161028130607|D100^電子^太郎^^^^^^^L^^^^^I||D100^電子^太郎^^^^^^^L^^^^^I|01^^^^^C||20161028083000||01^内科^HL70069^01^内科^99zzz|SHIENBU-PC2843^^99zzz|||テスト病院|^^^^^JPN^^東京都渋谷区本町x-y-z|^^^^^^^^^^^03-123-4567||||||O^外来患者オーダ^HL70482|" + "\r"
    msg = msg + "RXE||210630^アルファロールカプセル ０.２５μｇ^99zzz|1||CAP^カプセル^MR9P^CA^Ｃ^99zzz|TAB^錠剤^MR9P^01^錠・カプセル^99zzz|^^PRESMEDICINECOMMENT|||14|CAP^カプセル^MR9P^CA^Ｃ^99zzz||???????||8070||||1||^^PRESMEDICINECOMMENT|||||||||||||||||||||01^^^^^C||" + "\r"
    msg = msg + "TQ1|1||11N1&1日1回 朝食後&99zzz|||14^日分|2016102808|2016111000||||||" + "\r"
    msg = msg + "RXR|PO^口^HL70162|||||" + "\r"
    msg = msg + "ORC|NW|000000000001152||2|||||20161028130607|D100^電子^太郎^^^^^^^L^^^^^I||D100^電子^太郎^^^^^^^L^^^^^I|01^^^^^C||20161028083000||01^内科^HL70069^01^内科^99zzz|SHIENBU-PC2843^^99zzz|||テスト病院|^^^^^JPN^^東京都渋谷区本町x-y-z|^^^^^^^^^^^03-123-4567||||||O^外来患者オーダ^HL70482|" + "\r"
    msg = msg + "RXE||215012^タケプロンカプセル １５ｍｇ^99zzz|1||CAP^カプセル^MR9P^CA^Ｃ^99zzz|TAB^錠剤^MR9P^01^錠・カプセル^99zzz|^^PRESMEDICINECOMMENT|||14|CAP^カプセル^MR9P^CA^Ｃ^99zzz||???????||8070||||1||^^PRESMEDICINECOMMENT|||||||||||||||||||||01^^^^^C||" + "\r"
    msg = msg + "TQ1|1||11N1&1日1回 朝食後&99zzz|||14^日分|2016102808|2016111000||||||" + "\r"
    msg = msg + "RXR|PO^口^HL70162|||||" + "\r"
    msg = msg + "ORC|NW|000000000001152||3|||||20161028130607|D100^電子^太郎^^^^^^^L^^^^^I||D100^電子^太郎^^^^^^^L^^^^^I|01^^^^^C||20161028083000||01^内科^HL70069^01^内科^99zzz|SHIENBU-PC2843^^99zzz|||テスト病院|^^^^^JPN^^東京都渋谷区本町x-y-z|^^^^^^^^^^^03-123-4567||||||O^外来患者オーダ^HL70482|" + "\r"
    msg = msg + "RXE||215295^沈降炭酸カルシウム末^99zzz|1||GS^g(製剤量)^99zzz|PWD^散剤、ドライシロップ剤^MR9P^04^内服散剤^99zzz|^^PRESMEDICINECOMMENT|||42|GS^g(製剤量)^99zzz||???????||8070||||3||^^PRESMEDICINECOMMENT|||||||||||||||||||||01^^^^^C||" + "\r"
    msg = msg + "TQ1|1||13NM&1日3回 毎食後&99zzz|||14^日分|2016102808|2016111000||||||" + "\r"
    msg = msg + "RXR|PO^口^HL70162|||||" + "\r"
    msg = msg + "ORC|NW|000000000001152||3|||||20161028130607|D100^電子^太郎^^^^^^^L^^^^^I||D100^電子^太郎^^^^^^^L^^^^^I|01^^^^^C||20161028083000||01^内科^HL70069^01^内科^99zzz|SHIENBU-PC2843^^99zzz|||テスト病院|^^^^^JPN^^東京都渋谷区本町x-y-z|^^^^^^^^^^^03-123-4567||||||O^外来患者オーダ^HL70482|" + "\r"
    msg = msg + "RXE||211741^エンテロノン-Ｒ末^99zzz|1||GS^g(製剤量)^99zzz|PWD^散剤、ドライシロップ剤^MR9P^04^内服散剤^99zzz|^^PRESMEDICINECOMMENT|||42|GS^g(製剤量)^99zzz||???????||8070||||3||^^PRESMEDICINECOMMENT|||||||||||||||||||||01^^^^^C||" + "\r"
    msg = msg + "TQ1|1||13NM&1日3回 毎食後&99zzz|||14^日分|2016102808|2016111000||||||" + "\r"
    msg = msg + "RXR|PO^口^HL70162|||||" + "\r"
    # return msg.force_encoding("ISO-2022-JP")
    return msg
end

parser = HL7Parser.new(get_message_example)
puts parser.get_parsed_message()