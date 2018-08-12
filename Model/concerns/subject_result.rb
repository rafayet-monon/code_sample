# This concern calculates the fina result of a subject
module SubjectResult
  extend ActiveSupport::Concern

  module ClassMethods
    def calculate_subject_result(params, current_school, current_shift, current_session_batch)
      common_subject_term_and_type_result_variables(params, current_school, current_shift)
      class_exams = StudentExam.where(batch_class_id: params[:batch_class_id], session_batch_id: current_session_batch.id, exam_term_id: params[:exam_term_id], subject_id: params[:subject_id], is_published: :published)
      present_types = class_exams.pluck(:exam_type_id).uniq
      all_exam_types = ExamType.all
      final_hash = {}
      @class_students.each do |student|
        final_hash[student.id] = {}
        all_exam_types.each do |type|
          type_hash = {}
          particular_exam = class_exams.select{|b| b.exam_type_id == type.id}#(exam_type_id: type.id)
          type_hash[type.type_percentage] = {}
          if present_types.include? type.id
            particular_exam.each_with_index do |pexam, index|
              exam = pexam.student_exam_results.where(student_id: student.id)
              if exam.present?
                type_hash[type.type_percentage]["#{index}-#{pexam.exam_mark}"] = exam.first.mark_obtained
              else
                type_hash[type.type_percentage]["#{index}-#{pexam.exam_mark}"] = 'N/A'
              end
            end
            final_hash[student.id][type.id] = calculate_received_hash_total(type_hash)
          else
            final_hash[student.id][type.id] = 'N/A'
          end
        end
        values_array = final_hash[student.id].values
        delete_string_from_values =  values_array.delete_if{|i|i=='N/A'}
        if delete_string_from_values.empty?
          final_hash[student.id]['Total'] = 'N/A'
        else
          total = delete_string_from_values.sum
          final_hash[student.id]['Total'] = total
        end
      end
      final_hash.sort_by{|_,v| v["Total"] == 'N/A' ? 0 : v["Total"] }.reverse.to_h
    end
  end
end