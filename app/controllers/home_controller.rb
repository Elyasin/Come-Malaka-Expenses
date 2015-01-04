class HomeController < ApplicationController
  def index
  	redirect_to(events_path) if user_signed_in?
  end
end
