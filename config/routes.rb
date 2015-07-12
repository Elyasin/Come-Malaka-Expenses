Rails.application.routes.draw do

  mount JasmineRails::Engine => '/specs' if defined?(JasmineRails)

  devise_for :users, controllers: { invitations: :event_invitations, registrations: :registrations, sessions: :sessions }

  devise_scope :user do 
    match 'events/:event_id/invite', :to => 'event_invitations#new', :via => :get, :as => :invite_to_event
  end  

  root to: "home#index"

  resources :events do
    resources :items, shallow: true
  end
  get 'event_items/:event_id' => 'events#event_all_items', as: :event_all_items
  get 'expense_report/:event_id' => 'events#expense_report', as: :expense_report
  get 'who_owes_you/:event_id' => 'events#who_owes_you', as: :who_owes_you
  get 'you_owe_whom/:event_id' => 'events#you_owe_whom', as: :you_owe_whom

end
