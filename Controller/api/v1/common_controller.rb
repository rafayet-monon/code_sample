class Api::V1::CommonController < Api::V1::ApplicationController
  before_action :authenticate_current_user
  before_action :check_user, only: :get_class_subjects

  def get_batch_class
    # batch_classes = get_batch_classes(params)
    batch_classes = helpers.get_batch_class_selection
    json_response(batch_classes.order('id ASC'))
  end

  def get_class_subjects
    # current_shift = params[:current_shift] != 'undefined' ? Shift.find(params[:current_shift]) : Shift.first

    @current_class_id = if current_user.student?
                          student_class = current_user.class_students.find_by(session_batch_id: current_session_batch.id)
                          @batch_class = BatchClass.find(student_class.batch_class_id)
                          shift = Shift.find(student_class.shift_id)
                        elsif current_user.guardian?
                          student_class = current_child.class_students.find_by(session_batch_id: current_session_batch.id)
                          @batch_class = BatchClass.find(student_class.batch_class_id)
                          shift = Shift.find(student_class.shift_id)
                        else
                          shift = current_shift
                        end

    needed_params = {
        class_id: @batch_class.present? ? @batch_class.id : params[:class_id]
    }
    subjects = CommonMethods.get_class_subject_json(needed_params, shift, current_user)
    p subjects
    json_response(subjects)
  end

  def get_batch_classes(params)
    current_shift = params[:current_shift] != 'undefined' ? Shift.find(params[:current_shift]) : Shift.first
    current_session_batch = params[:current_session_batch] != 'undefined' ? SessionBatch.find(params[:current_session_batch]) : SessionBatch.first
    if current_user.school_admin?
      current_shift.batch_classes.where(has_section: 1, session_batch_id: current_session_batch.id)
    elsif current_user.teacher?
      class_schedules = current_user.class_schedules.where(session_batch_id: current_session_batch.id, shift_id: current_shift.id ).pluck(:batch_class_id)
      BatchClass.find(class_schedules)
    else
      current_class_student = if current_user.student?
                                current_user.class_students.find_by(session_batch_id: current_session_batch.id)
                              else
                                current_child.class_students.find_by(session_batch_id: current_session_batch.id) if current_child.present?
                              end
      BatchClass.where(id: current_class_student.batch_class_id) if current_class_student.present?
    end
  end

end