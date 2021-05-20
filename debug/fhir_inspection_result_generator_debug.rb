require "base64"
require './lib/fhir_inspection_result_generator'
filename = File.join(File.dirname(__FILE__), "example_inspection_result.txt")
params = {
  encoding: "UTF-8",
  prefecture_code: "13",
  medical_fee_point_code: "1",
  medical_institution_code: "9999999",
  message: Base64.encode64(File.read(filename, encoding: "utf-8")),
}
generator = FhirInspectionResultGenerator.new(params).perform
result = generator.to_json
puts result
