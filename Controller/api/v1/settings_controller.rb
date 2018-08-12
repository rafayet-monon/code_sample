class Api::V1::SettingsController < Api::V1::ApplicationController
  before_action :authenticate_current_user
  def guardian_children
    children = current_user.children.order("id ASC")
    json_response(children)
  end

  def ta_shift_sessions
    school = current_user.school
    shifts = school.shifts
    session_batches = school.session_batches
    json_response({shifts: shifts, session_batches: session_batches})
  end
end