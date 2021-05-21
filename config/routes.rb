Rails.application.routes.draw do
    root to: "fhir_testers#index"

    resources :fhir_testers do
        member do
        end
    end

    namespace :api do
        namespace :hl7 do
            resources :fhir_prescription_generators, only: %i[create]
            resources :fhir_injection_generators, only: %i[create]
            resources :fhir_inspection_result_generators, only: %i[create]
            resources :v2_message_parsers, only: %i[create]
        end
    end
end
