# == Schema Information
#
# Table name: student_exams
#
#  id                   :integer          not null, primary key
#  exam_title           :string
#  exam_term_id         :integer
#  exam_type_id         :integer
#  shift_id             :integer
#  batch_class_id       :integer
#  session_batch_id     :integer
#  school_id            :integer
#  class_room_id        :integer
#  exam_date            :date
#  exam_start_time      :time
#  exam_end_time        :time
#  subject_id           :integer
#  exam_mark            :integer
#  is_published         :integer          default("unpublished")
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  is_finalized         :integer          default("not_finalized")
#  syllebus_instruction :text
#  attachment           :text
#  slug                 :string
#

class StudentExam < ApplicationRecord
  include PublicActivity::Common

  has_many :activities, as: :trackable, class_name: 'PublicActivity::Activity', dependent: :destroy
  belongs_to :school
  belongs_to :exam_term
  belongs_to :exam_type
  belongs_to :batch_class
  belongs_to :session_batch
  belongs_to :shift
  belongs_to :class_room
  belongs_to :subject
  has_many :student_exam_results, dependent: :destroy

  mount_uploader :attachment, AttachmentUploader

  enum is_published: %i[unpublished published]
  enum is_finalized: %i[not_finalized finalized]

  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  accepts_nested_attributes_for :student_exam_results,
                                allow_destroy: true,
                                reject_if: :all_blank

  def slug_candidates
    [
        :exam_details,
        [:exam_details, :id]
    ]
  end

  def exam_details
    batch_class = self.batch_class.name
    term = self.exam_term.term_name
    type = self.exam_type.type_name
    "#{exam_title}-#{batch_class}-#{term}-#{type}"
  end

end
