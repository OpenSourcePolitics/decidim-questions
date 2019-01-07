# frozen-string_literal: true

module Decidim
  module Questions
    class EvaluatingQuestionEvent < Decidim::Events::SimpleEvent
      def event_has_roles?
        true
      end
    end
  end
end
