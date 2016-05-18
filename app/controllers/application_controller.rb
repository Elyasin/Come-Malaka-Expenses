class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  acts_as_token_authentication_handler_for User

  def after_sign_in_path_for(resource_or_scope)
  	events_path
	end

  def after_sign_out_path_for(resource_or_scope)
  	root_path
	end

  def after_sign_up_path_for(resource_or_scope)
  	events_path
	end

  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit( :sign_up, keys: [ :first_name, :last_name ] )
    #devise_parameter_sanitizer.for(:sign_up) << :first_name << :last_name
    devise_parameter_sanitizer.permit( :account_update, keys: [ :first_name, :last_name ] )
    #devise_parameter_sanitizer.for(:account_update) << :first_name << :last_name
    devise_parameter_sanitizer.permit( :invite, keys: [ :event_id, :first_name, :last_name ] )
    #devise_parameter_sanitizer.for(:invite) << :event_id << :first_name << :last_name
  end

end
