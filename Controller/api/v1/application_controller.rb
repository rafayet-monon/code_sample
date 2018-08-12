class Api::V1::ApplicationController < ApplicationController
  skip_before_action :verify_authenticity_token
  include DeviseTokenAuth::Concerns::SetUserByToken
  include Response
  include ExceptionHandler

  before_action :check_shift, :check_session_batch

  def authenticate_current_user
    head :unauthorized if get_current_user.nil?
  end

  def get_current_user
    auth_headers = request.headers
    return nil unless auth_headers['uid'].present? && auth_headers['client'].present? && auth_headers['expiry'].present?
    expiration_datetime = Date.strptime(auth_headers['expiry'], '%s')
    current_user = User.find_by(uid: auth_headers['uid'])
    if current_user && current_user.tokens.key?(auth_headers['client']) && expiration_datetime > DateTime.now
      @current_user = current_user
    end
    @current_user
  end

  def check_user
    if current_user.guardian?
      @child_id = params[:child_id]
      current_child
    end
  end

  def current_child
    User.find(@child_id) if current_user.guardian?
  rescue ActiveRecord::RecordNotFound
    current_user.children.first
  end

  def check_shift
    if params[:shift_id].present?
      @shift_id = params[:shift_id]
      current_shift
    end
  end

  def current_shift
    Shift.find(@shift_id)
  rescue ActiveRecord::RecordNotFound
    Shift.first
  end

  def check_session_batch
    if params[:session_batch_id].present? && params[:session_batch_id] != 'undefined'
      @session_batch_id = params[:session_batch_id]
      current_session_batch
    end
  end

  def current_session_batch
    SessionBatch.find(@session_batch_id)
  rescue ActiveRecord::RecordNotFound
    ongoing_session = @session_batches.find_by("year LIKE ?", "%#{Time.now.year - 1}%")
    ongoing_session.present? ? ongoing_session : SessionBatch.first
  end

end