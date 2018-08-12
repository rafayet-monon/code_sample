class Api::V1::NotificationsController < Api::V1::ApplicationController
  before_action :authenticate_current_user
  def user_notifications
    @all_html = []
    @current_user_notifications = current_user.activity_recipients.all.reverse if current_user.present?
    # json_response(@current_user_notifications)
  end
end