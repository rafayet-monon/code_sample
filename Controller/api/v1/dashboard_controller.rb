class Api::V1::DashboardController < Api::V1::ApplicationController
  before_action :authenticate_current_user, :check_user

  include StudentParentDashboardsFunctions
  include TeacherDashboardsFunctions

  def dashboard
    if current_user.student? || current_user.guardian?
      sp_dashboard_attendance
    else
      ta_dashboard_attendance
    end

  end

  def ta_dashboard_attendance
    find_attendance_report_for_teacher_admin_dashboard
    json_response(ta_graph_hash)
  end

  def ta_graph_hash
    {
        lowest: @lowest.present? ? @lowest : [],
        lowest_holders: @lowest_holders.present? ? @lowest_holders : [],
        highest: @highest.present? ? @highest : [],
        highest_holders: @highest_holders.present? ? @highest_holders : [],
        average: @average.present? ? @average : [],
    }
  end

  def sp_dashboard_attendance
    if params[:subject_id] != 'undefined' && !params[:subject_id].empty?
      student_parent_monthly_attendance_report
      json_response(sp_graph_hash)
    else
      student_parent_yearly_attendance_report
      json_response(sp_graph_hash)
    end
  end

  def sp_graph_hash
    {
        current_student: @current_student_data.present? ? @current_student_data : [],
        current_present: @present_days.present? ? @present_days : [],
        highest_student: @highest_student_data.present? ? @highest_student_data : [],
        highest_present: @highest_present_days.present? ? @highest_present_days : [],
        total_class: @total_classes.present? ? @total_classes : [],
        subject: @subject_names.present? ? @subject_names : []
    }
  end

  def recent_notice_events
    notices = current_school.notice_boards.last(5).reverse
    events = current_school.events.where("start > ?", Time.now).order('start asc').first(5)
    recent_notices = []
    upcoming_events = []
    notices.each do |notice|
      recent_notices << {
          title: notice.title,
          expiry_date: notice.expiration_date.strftime('%a, %d %b, %Y')
      }
    end
    events.each do |event|
      upcoming_events << {
          title: event.title,
          time: "#{event.start.strftime('%a, %d %b %Y %l:%M %p')} - #{event.end.strftime('%a, %d %b %Y %l:%M %p')}"
      }
    end
    json_response(recent_notices: recent_notices, upcoming_events: upcoming_events)
  end

end