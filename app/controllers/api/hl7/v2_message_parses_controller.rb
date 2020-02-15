# encoding: utf-8
require 'json'
require './lib/hl7v2/hl7parser'

class Api::Hl7::V2MessageParsesController < ApplicationController
    def create
        # POST：リクエストBODYに設定されたHL7RawDataをJSON形式にパースして返す
        raw_message = request.body.read
        parser = HL7Parser.new(raw_message)
        render json: parser.get_parsed_message
    end
end