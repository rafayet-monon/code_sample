class StudentExamResultsController < ApplicationController
  include CardCollection
  before_action :authenticate_user!
  before_action :set_student_exam_result, only: %i[show edit update destroy]


  def index
    @exam = StudentExam.find(params[:exam])
    @student_exam_results = StudentExamResult.where(student_exam_id: @exam.id).order("mark_obtained DESC")
    respond_to do |format|
      format.html
    end
  end


  def show; end


  def new
    @exam = StudentExam.find(params[:exam])
    @student_result_array = StudentExamResult.get_exam_students(@exam, params[:shift_id])
    respond_to do |format|
      if @student_result_array.present?
        format.html
      else
        format.html { redirect_to student_exams_path, alert: 'No student available to publish result. Please add students to the class.'}
      end
    end
  end


  def edit; end


  def create; end


  def update; end


  def destroy
    @student_exam_result.destroy
    respond_to do |format|
      format.html { redirect_to student_exam_results_url, notice: 'Student exam result was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def exam_result_reports
    @available_batch_classes = helpers.get_batch_class_selection
    @terms = current_school.exam_terms.all
    @types = current_school.exam_types.all
  end

  def find_term_based_result
    common_report_variables(params)
    @term_result = StudentExamResult.get_term_results(params, current_school, current_shift, current_session_batch)
    respond_to do |format|
      if !params[:exam_term_id].present?
        format.html { redirect_to exam_result_reports_student_exam_results_path, alert: 'Select a Term to see report.'}
      else
        if @term_result.empty?
          format.html { redirect_to exam_result_reports_student_exam_results_path, alert: 'Cannot create report without any student.'}
        else
          format.html
        end
      end
    end
  end

  def find_subject_based_result
    common_report_variables(params)
    @subject_result = StudentExamResult.get_subject_result(params, current_school, current_shift, current_session_batch)
    respond_to do |format|
      format.html
    end
  end

  def find_type_based_result
    common_report_variables(params)
    @type_result = StudentExamResult.get_type_result(params, current_school, current_shift, current_session_batch)
    respond_to do |format|
      format.html
    end
  end

  def common_report_variables(params)
    @exam_term = ExamTerm.find(params[:exam_term_id]) if params[:exam_term_id].present?
    @batch_class = BatchClass.find(params[:batch_class_id]) if params[:batch_class_id].present?
    @subject = Subject.find(params[:subject_id]) if params[:subject_id].present?
    @exam_type = ExamType.find(params[:exam_type_id]) if params[:exam_type_id].present?
  end

  private
  def set_student_exam_result
    @student_exam_result = StudentExamResult.find(params[:id])
  end

  def student_exam_result_params(result)
    result.permit(:student_exam_id, :student_id, :mark_obtained, :teacher_id)
  end
end
