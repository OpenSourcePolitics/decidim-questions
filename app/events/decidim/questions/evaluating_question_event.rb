# frozen-string_literal: true

module Decidim
  module Questions
    class EvaluatingQuestionEvent < Decidim::Questions::Admin::QuestionEvent
      def event_has_roles?
        true
      end
    end
  end
end
