# == Schema Information
#
# Table name: student_exam_results
#
#  id              :integer          not null, primary key
#  student_exam_id :integer
#  student_id      :integer
#  teacher_id      :integer
#  mark_obtained   :float            default(0.0)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  student_status  :integer          default(1)
#

class StudentExamResult < ApplicationRecord
  include PublicActivity::Common

  has_many :activities, as: :trackable, class_name: 'PublicActivity::Activity', dependent: :destroy
  include FinalResult
  include SubjectResult
  include TypeResult
  include TeacherDashboardExamReport
  belongs_to :student_exam
  belongs_to :student, class_name: 'User', foreign_key: 'student_id'
  belongs_to :teacher, class_name: 'User', foreign_key: 'teacher_id', optional: :true

  after_save :update_exam_status

  class << self
    def get_exam_students(exam, shift_id)
      batch_class = BatchClass.find(exam.batch_class_id)
      exam_results = exam.student_exam_results
      class_student_ids = ClassStudent.where(batch_class_id: batch_class.id, shift_id: shift_id).pluck(:student_id)
      class_students = User.find(class_student_ids)
      student_result_array = []
      if exam_results.present?
        exam_results.each do |result|
          student_result_array << result
        end
      else
        class_students.each do |student|
          student_result_array << exam.student_exam_results.build(student_id: student.id)
        end
      end
      student_result_array
    end
  end

  def self.get_term_results(params, current_school, current_shift, current_session_batch)
    calculate_term_result(params, current_school, current_shift, current_session_batch)
  end

  def self.get_subject_result(params, current_school, current_shift, current_session_batch)
    calculate_subject_result(params, current_school, current_shift, current_session_batch)
  end

  def self.get_type_result(params, current_school, current_shift, current_session_batch)
    calculate_type_result(params, current_school, current_shift, current_session_batch)
  end

=begin
  for dashboard start
=end

  def self.get_term_based_student_result_for_dashboard(params, exam_terms, current_school, batch_class, current_class_student, selected_term)
    needed_params = {batch_class_id: batch_class.id, exam_term_id: selected_term.id}
    student_shift = Shift.find(current_class_student.shift_id)
    student_session_batch = Shift.find(current_class_student.session_batch_id)
    exam_results = self.get_term_results(needed_params, current_school, student_shift, student_session_batch)
  end

  def self.get_student_result_array_for_dashboard(current_student_hash)
    current_student_hash_without_total = current_student_hash.take(current_student_hash.size-1)
    current_student_result_x_axis = []
    current_student_hash_without_total.each do |chash|
      current_student_result_x_axis << chash[:mark]
    end
    current_student_result_x_axis
  end

  def self.get_term_results_for_teacher_report(assigned_subjects, selected_term, current_shift, current_session_batch, current_school)
    graph_hash = calculate_term_results_for_teacher_report(assigned_subjects, selected_term, current_shift, current_session_batch, current_school)
  end

=begin
  dashboard ends
=end

  private

  def update_exam_status
    exam = StudentExam.find(student_exam_id)
    exam.update_attributes(is_published: :published)
  end

  def self.common_subject_term_and_type_result_variables(params, current_school, current_shift)
    student_ids = ClassStudent.where(batch_class_id: params[:batch_class_id], shift_id: current_shift.id).pluck(:student_id)
    @class_students = User.find(student_ids)
    @exam_types = current_school.exam_types
  end

  # type_hash = {type_percentage => {"exam_index_number - exam_mark"=> mark_obtained},.....}
  def self.calculate_received_hash_total(type_hash)
    type_hash.each_key do |key, value|
      obtained_mark_sum = type_hash[key].inject(0) do |sum, tuple|
        if (!tuple[1].is_a? String) && (!tuple[1].nil?)
          sum += tuple[1]
        end
        sum
      end
      exam_mark_sum = type_hash[key].inject(0) do |sum, tuple|
        exam_mark = tuple[0].split('-').last.to_i
        sum += exam_mark
      end
      type_hash[key] = if obtained_mark_sum.nil?
                         'N/A'
                       else
                         calculate_type_total(key, obtained_mark_sum, exam_mark_sum)
                       end
    end
    if type_hash.values.include? 'N/A'
      'N/A'
    else
      type_hash.values.sum.round(2)
    end
  end

  def self.calculate_type_total(percentage, obtained_mark_sum, exam_mark_sum)
    ((percentage * obtained_mark_sum) / exam_mark_sum).round(2)
  end

end
