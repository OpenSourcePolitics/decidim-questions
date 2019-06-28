# frozen-string_literal: true

module Decidim
  module Questions
    class RejectedQuestionEvent < Decidim::Questions::Admin::QuestionEvent
      def resource_text
        question_answer
      end

      def event_has_roles?
        true
      end
    end
  end
end
