# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A form object to be used when admin users want to create a question.
      class QuestionNoteForm < Decidim::Form
        mimic :question_note

        attribute :body, String

        validates :body, presence: true
      end
    end
  end
end
