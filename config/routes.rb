Rails.application.routes.draw do
    # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

    # namespace :api, {format: 'json'} do
    namespace :api do
      namespace :hl7 do
        resources :v2_message_parses, only: %i[create]
        resources :fhir_prescription_generators, only: %i[create]
        resources :fhir_inspection_result_generators, only: %i[create]
        resources :fhir_patient_generators, only: %i[create]
      end
    end
end
