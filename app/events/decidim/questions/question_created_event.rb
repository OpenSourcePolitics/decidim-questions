# frozen-string_literal: true

module Decidim
  module Questions
    class QuestionCreatedEvent < Decidim::Events::BaseEvent
      include Decidim::Events::EmailEvent
      include Decidim::Events::NotificationEvent

      def notification_title
        I18n.t(
          "decidim.events.question_created.notification_title",
          resource_title: resource_title,
          resource_path: resource_locator.path(url_params),
          author_name: question.author.name
        ).html_safe
      end

      def email_url
        I18n.t(
          "decidim.events.question_created.url",
          resource_url: resource_locator.url(url_params)
        ).html_safe
      end

      def email_subject
        I18n.t(
          "decidim.events.question_created.email_subject",
          author_name: question.author.name
        ).html_safe
      end

      def email_moderation_intro
        I18n.t(
          "decidim.events.question_created.moderation.email_intro",
          resource_title: resource_title,
          author_name: question.author.name
        ).html_safe
      end

      def email_moderation_subject
        I18n.t(
          "decidim.events.question_created.moderation.email_subject",
          resource_title: resource_title,
          resource_url: resource_locator.url(url_params),
          author_name: question.author.name
        ).html_safe
      end

      def email_moderation_url(moderation_url)
        I18n.t(
          "decidim.events.question_created.moderation.moderation_url",
          moderation_url: moderation_url
        ).html_safe
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
