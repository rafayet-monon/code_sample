class Api::V1::EventsController < Api::V1::ApplicationController
  before_action :authenticate_current_user
  def index
    events = Event.all
    p events
    json_response(events)
  end
end