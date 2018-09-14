# frozen-string_literal: true

module Decidim
  module Questions
    class QuestionNeedModerationEvent < Decidim::Events::SimpleEvent
      # include Decidim::Events::EmailEvent
      include Decidim::Events::AuthorEvent
      # include Decidim::Events::NotificationEvent

      private

      def i18n_scope
        return super unless participatory_space_event?
        if author?
          "decidim.events.questions.question_need_moderation_for_author"
        else
          "decidim.events.questions.question_need_moderation_for_moderators"
        end
      end

      def participatory_space_event?
        extra.dig(:participatory_space)
      end

      def author?
        extra.dig(:author)
      end

    end
  end
end
