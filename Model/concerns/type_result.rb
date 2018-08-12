# This concern calculates the fina result of a subject
module TypeResult
  extend ActiveSupport::Concern

  module ClassMethods
    def calculate_type_result(params, current_school, current_shift, current_session_batch)
      common_subject_term_and_type_result_variables(params, current_school, current_shift)
      type_exams = StudentExam.where(batch_class_id: params[:batch_class_id], session_batch_id: current_session_batch.id, exam_term_id: params[:exam_term_id], subject_id: params[:subject_id], exam_type_id: params[:exam_type_id], is_published: :published)
      exam_type = ExamType.find(params[:exam_type_id])
      final_hash = {}
      @class_students.each do |student|
        final_hash[student.id] = {}
        next unless type_exams.present?
        total_exam_mark = 0
        total_obtained_mark = 0
        type_exams.each do |pexam|
          exam_result = pexam.student_exam_results.where(student_id: student.id)
          total_exam_mark += pexam.exam_mark
          if exam_result.present?
            total_obtained_mark += exam_result.first.mark_obtained
            final_hash[student.id][pexam.exam_title] = { mark: exam_result.first.mark_obtained, status: exam_result.first.student_status }
          else
            final_hash[student.id][pexam.exam_title] = { mark: 'N/A', status: 'N/A' }
          end
        end
        total = if final_hash[student.id].values.first[:mark] == 'N/A'
                  'N/A'
                else
                  calculate_type_total(exam_type.type_percentage, total_obtained_mark, total_exam_mark )
                end
        final_hash[student.id]["Total"] = total
      end
      final_hash.sort_by{|_,v| v["Total"] == 'N/A' ? 0 : v["Total"] }.reverse.to_h
    end
  end
end