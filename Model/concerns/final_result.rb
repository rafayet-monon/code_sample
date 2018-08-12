# This concern calculates the fina result of a term
module FinalResult
  extend ActiveSupport::Concern

  module ClassMethods
    def calculate_term_result(params, current_school, current_shift, current_session_batch)
      common_subject_term_and_type_result_variables(params, current_school, current_shift )
      term_result_variables(params, current_school, current_session_batch,  current_shift)
      final_hash = {}
      @class_students.each do |student|
        student_results = student.student_exam_results.all
        final_hash[student.id] = {}
        @all_subjects.each do |subject|
          finalized_exam_type_ids = @class_exams.select{|b| b.subject_id == subject.id} #.where(subject_id: subject.id)
          if finalized_exam_type_ids.pluck(:exam_type_id).sort.uniq == @exam_types.pluck(:id).sort
            final_hash[student.id][subject.id] = { mark: 0.0 }
            type_hash = {}
            @exam_types.each do |type|
              type_hash[type.type_percentage] = {}
              particular_exam = @class_exams.select{|b| b.exam_type_id == type.id && b.subject_id == subject.id} #.where(exam_type: type.id, subject_id: subject.id)
              particular_exam.each_with_index do |pexam, index|
                exam = student_results.find{|b| b.student_exam_id == pexam.id && b.student_id == student.id } #pexam.student_exam_results.find_by(student_id: student.id)
                if exam.present?
                  type_hash[type.type_percentage]["#{index}-#{pexam.exam_mark}"] = exam.mark_obtained
                else
                  type_hash[type.type_percentage]["#{index}-#{pexam.exam_mark}"] = 'N/A'
                end
              end
            end

            final_hash[student.id][subject.id][:mark] = calculate_received_hash_total(type_hash)
          else
            final_hash[student.id][subject.id] = { mark: 'N/A' }
          end
        end
        final_hash[student.id]
        total = get_total_mark(final_hash[student.id])
        final_hash[student.id]['Total'] = { mark: total }
      end
      final_hash.sort_by{|_,v| v["Total"].values.first == 'N/A' ? 0 : v["Total"].values.first }.reverse.to_h
    end

    def term_result_variables(params, current_school, current_session_batch, current_shift)
      @class_exams = StudentExam.where(batch_class_id: params[:batch_class_id], session_batch_id: current_session_batch.id, exam_term_id: params[:exam_term_id], is_finalized: :finalized)
      @finalized_exam_type_ids = @class_exams.pluck(:exam_type_id)
      batch_class = BatchClass.find(params[:batch_class_id])
      all_subject_ids = batch_class.class_schedules.where(shift_id: current_shift.id).pluck(:subject_id)
      @all_subjects = Subject.find(all_subject_ids.uniq)
    end

    def get_finalized_subjects(class_exams)
      exam_subject_id_array = []
      class_exams.each do |cx|
        exam_subject_id_array << Subject.find(cx.subject_id)
      end
      exam_subject_id_array.uniq!
    end

    def get_total_mark(student_hash)
      mark_array = []
      student_hash.values.each do |v|
        mark_array << v[:mark]
      end
      delete_string_from_values =  mark_array.delete_if{|i|i=='N/A'}
      if mark_array.empty?
        total_hash = 'N/A'
      else
        total_hash = 0
        student_hash.each do |key, value|
          sum = value.inject(0) do |sum, tuple|
            sum += tuple[1] unless tuple[1].is_a? String
            sum
          end
          total_hash += sum
        end
      end
      total_hash
    end

    def sort_hash
      final_hash.sort_by{|_,v| v["Total"].values.first.is_a? String ? v["Total"].values.first : '' }.reverse.to_h
    end
  end
end
