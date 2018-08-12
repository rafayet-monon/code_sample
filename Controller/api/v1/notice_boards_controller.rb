class Api::V1::NoticeBoardsController < Api::V1::ApplicationController
  before_action :authenticate_current_user
  def index
    notices = NoticeBoard.all
    json_response(notices)
  end
end