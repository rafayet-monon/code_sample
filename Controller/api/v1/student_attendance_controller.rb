class Api::V1::StudentAttendanceController < Api::V1::ApplicationController
  include CardCollection

  def index
    create_card_hash
    all_available_subjects =@all_available_subjects.each do |sub|
      sub[:weekdays] = sub[:weekdays].to_a
    end
    json_response(all_available_subjects)
  end

  def find_daily_report
    batch_class = BatchClass.find(params[:class_id])
    info = "#{params[:month]} for #{helpers.get_batch_class_name(batch_class)}"
    @attendance_report = StudentAttendance.get_daily_attendance_report(params, current_shift, current_session_batch, current_school) if params[:month].present?
    month_days = make_month_hash
    student_report = make_report
    json_response(days: month_days, reports: student_report, info: info)
  end

  def make_month_hash
    month_days = []
    @attendance_report.first[1].each_with_index do |(key, value), index |
      unless index == @attendance_report.first[1].size - 1
        month_days << key
      end
    end
    month_days
  end

  def make_report
    individual = Array.new(@attendance_report.keys.count) { Array.new }
    @attendance_report.each_with_index do |(s_id, s_value), s_index|
      individual[s_index] << s_value[:credential][:roll_no]
      individual[s_index] << s_value[:credential][:name]
      s_value.each_with_index do |(key, val), index|
        unless index == s_value.size - 1
          individual[s_index] << val[:status]
        end
      end
    end
    individual
  end

  def get_students_for_call
    p Time.now.utc
    class_students = CommonMethods.get_class_students(params, current_shift)
    process_class_student_variables if params[:attendance_date].present?
    if @schedule.present?
      @student_attendance = StudentAttendance.where(class_schedule_id: @schedule.first.id).where(attendance_date: params[:attendance_date])
      @attendances_arr = StudentAttendance.get_attendance_array(@student_attendance, @batch_class, params, class_students, current_shift, @schedule)
    end
    add_name_roll_to_array if @attendances_arr.present?
    if !@weekday.present?
      json_response(msg:  "Please Select a date.")
    elsif @holidays.include? @weekday.first.id
      json_response(msg:  'No Schedules on Holiday')
    elsif @schedule.empty?
      json_response(msg: "No #{@subject.name} Schedules on #{@weekday.first.name} of #{helpers.get_batch_class_name(@batch_class)}")
    elsif class_students.empty?
      json_response(msg: "No Student in #{helpers.get_batch_class_name(@batch_class)}")
    else
      json_response(att_data: @attendances_arr.as_json, message: "#{helpers.attendance_creation_status(@student_attendance)}")
    end
  end

  def process_class_student_variables
    @batch_class = BatchClass.find(params[:class_id])
    @subject = Subject.find(params[:subject_id])
    @shifts = Shift.all
    @weekday_name = Date.parse(params[:attendance_date]).strftime('%A')
    @weekday = Weekday.where('name LIKE ?', "#{@weekday_name}")
    @schedule = ClassSchedule.where(shift_id: current_shift.id, batch_class_id: @batch_class.id, weekday_id: @weekday.first.id, subject_id: params[:subject_id])
    @holidays = current_school.weekly_school_holidays.pluck(:weekday_id)
  end

  def add_name_roll_to_array
    @attendances_arr = @attendances_arr.as_json.each do |std|
      std['roll_no'] = helpers.get_student_roll(std['student_id'])
      std['name'] = helpers.get_student_name_only(std['student_id'])
    end
  end

  def create_attendance
    permitted = params.permit!
    first_param = permitted[:data].first.to_h
    shift_id = current_shift.id
    batch_class_id = first_param[:batch_class_id]
    class_schedule_id = first_param[:class_schedule_id]
    teacher_id = current_user.id
    attendance_date = first_param[:attendance_date]

    permitted[:data].each do |att|
      att_hash = att.to_h
      if att_hash[:status].nil?
        att_hash[:status] = 1
      end
      if att[:id].nil?
        StudentAttendance.create!(shift_id: shift_id, batch_class_id: batch_class_id,
                                 class_schedule_id: class_schedule_id, teacher_id: teacher_id, attendance_date: attendance_date,
                                 status: att_hash[:status], student_id: att_hash[:student_id])
      else
        attendance = StudentAttendance.find(att_hash[:id])
        attendance.update_attributes(status: att_hash[:status])
      end
    end
    json_response(message: 'Attendance Taken Successfully!')
  end

end
