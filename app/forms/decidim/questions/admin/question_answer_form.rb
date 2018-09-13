# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A form object to be used when admin users want to answer a question.
      class QuestionAnswerForm < Decidim::Form
        include TranslatableAttributes
        mimic :question_answer

        translatable_attribute :answer, String
        attribute :state, String
        attribute :recipient_role, String

        validates :state, presence: true, inclusion: { in: %w(accepted rejected evaluating) }
        validates :answer, translatable_presence: true, if: ->(form) { form.state == "rejected" }
        # validates :recipient_role, presence: true, if: ->(form) { form.question_type == "question" }
      end
    end
  end
end
