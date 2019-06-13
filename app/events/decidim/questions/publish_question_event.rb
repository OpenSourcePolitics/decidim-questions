# frozen-string_literal: true

module Decidim
  module Questions
    class PublishQuestionEvent < Decidim::Questions::Admin::QuestionEvent
      include Decidim::Events::CoauthorEvent

      def resource_text
        resource.body
      end

      private

      def i18n_scope
        return super unless participatory_space_event?

        "decidim.events.questions.question_published_for_space"
      end

      def participatory_space_event?
        extra.dig(:participatory_space)
      end
    end
  end
end
