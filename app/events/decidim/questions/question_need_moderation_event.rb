# frozen-string_literal: true

module Decidim
  module Questions
    class QuestionNeedModerationEvent < Decidim::Events::SimpleEvent
      include Decidim::Events::EmailEvent
      include Decidim::Events::AuthorEvent
      include Decidim::Events::NotificationEvent

      def email_subject
        I18n.t(
          "decidim.events.questions.question_need_moderation.email_subject").html_safe
      end

      def email_intro
        I18n.t(
          "decidim.events.questions.question_need_moderation.email_intro").html_safe
      end

      def email_outro
        I18n.t(
          "decidim.events.questions.question_need_moderation.email_outro").html_safe
      end

      private

      def question
        @question ||= Decidim::Questions::Question.find(resource.id)
      end

      def url_params
        { anchor: "question_#{question.id}" }
      end
    end
  end
end
