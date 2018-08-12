class StudentExamsController < ApplicationController
  before_action :authenticate_user!
  include CardCollection
  before_action :set_student_exam, only: [:show, :edit, :update, :destroy]
  authorize_resource

  def index
    student_exam_form_instances
    create_card_hash
    if params[:exam_term_id].present?
      @exams = StudentExam.where(shift_id: current_shift.id, session_batch_id: current_session_batch.id, batch_class_id: params[:class_id], exam_term_id: params[:exam_term_id], subject_id: params[:subject_id])
    end
    respond_to do |format|
      format.html
      format.js
    end
  end


  def show
  end

  def new
    student_exam_form_instances
    @selected_batch_class = helpers.get_batch_class_selection.first.id
    needed_params = {batch_class_id: @selected_batch_class}
    @available_subjects = CommonMethods.get_class_subjects(needed_params,current_user, current_shift, current_session_batch)
    @student_exam = StudentExam.new
  end

  def edit
    @selected_batch_class = @student_exam.batch_class_id
    needed_params = {batch_class_id: @selected_batch_class}
    @available_subjects = CommonMethods.get_class_subjects(needed_params,current_user, current_shift, current_session_batch)
    student_exam_form_instances
  end

  def create
    @student_exam = current_school.student_exams.build(student_exam_params.merge(shift_id:current_shift.id, session_batch_id: current_session_batch.id))

    respond_to do |format|
      if @student_exam.save!
        create_activity = @student_exam.create_activity :create, owner: current_user
        if create_activity
          ExamNotificationRecipientWorker.perform_async(create_activity.id, @student_exam.id)
        end
        format.html do
          redirect_to student_exams_path, notice: 'Exam schedule Created'
        end
      else
        student_exam_form_instances
        format.html { render :new }
      end
    end
  end


  def update
    respond_to do |format|
      if @student_exam.update!(student_exam_params)
        if student_exam_params[:student_exam_results_attributes].present?
          publish_exam_result
          format.html do
            redirect_to student_exams_path, notice: 'Result Published'
          end
        else
          create_exam_update_activity
          format.html do
            redirect_to student_exams_path, notice: 'Exam schedule Updated'
          end
        end
      else
        redirect_to student_exams_path, alert: 'Please Try Again.'
      end
    end
  end

  def publish_exam_result
    @student_exam.update_attributes(is_published: :published)
    create_result_publish_activity
  end

  def create_result_publish_activity
    first_value = student_exam_params[:student_exam_results_attributes]['0']
    unless first_value[:id].present?
      create_activity = @student_exam.create_activity :result_published, owner: current_user
    end
    if create_activity
      ExamNotificationRecipientWorker.perform_async(create_activity.id, @student_exam.id)
    end
  end

  def create_exam_update_activity
    create_activity = @student_exam.create_activity :update, owner: current_user
    if create_activity
      ExamNotificationRecipientWorker.perform_async(create_activity.id, @student_exam.id)
    end
  end

  def destroy
    @student_exam.destroy
    data = [result: 'success']
    create_activity = @student_exam.create_activity :destroy, owner: current_user
    # if create_activity
    #   ExamNotificationRecipientWorker.perform_async(create_activity.id, @student_exam.id)
    # end
    return render json: data
  end

  def find_scheduled_class
    subjects = CommonMethods.get_class_subjects(params,current_user, current_shift, current_session_batch)
    respond_to do |format|
      format.json { render json: subjects }
    end
  end

  def finalize_published_result
    ids_array = []
    params['student_exam_ids'].each do |element|
      ids_array << element['id'].to_i
    end
    exams = StudentExam.find(ids_array)
    # update each exams is_finalized to 1 or 0
    params[:status] == 'finalized' ? exams.each(&:finalized!) : exams.each(&:not_finalized!)
    redirect_to student_exams_path, notice: params[:status] == 'finalized' ? 'Final result published' : 'Final Result Unpublished'
  end

  def student_exam_form_instances
    @room = current_school.class_rooms.classrooms
    @terms = current_school.exam_terms.all
    @types = current_school.exam_types.all
  end

  private
  def set_student_exam
    @student_exam = StudentExam.friendly.find(params[:id])
  end

  def student_exam_params
    params.require(:student_exam).permit(:exam_term_id, :exam_type_id, :shift_id, :batch_class_id, :session_batch_id, :school_id, :class_room_id, :exam_date, :exam_title, :exam_start_time, :exam_end_time, :subject_id, :exam_mark, :syllebus_instruction, :attachment, :student_exam_results_attributes => {})
  end
end
