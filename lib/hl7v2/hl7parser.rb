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
        parse(raw_message) if !raw_message.nil?
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