# frozen_string_literal: true

module Decidim
  module Questions
    # A command with all the business logic when a user publishes a draft question.
    class PublishQuestion < Rectify::Command
      # Public: Initializes the command.
      #
      # question     - The question to publish.
      # current_user - The current user.
      def initialize(question, current_user)
        @question = question
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid and the question is published.
      # - :invalid if the question's author is not the current user.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if @question.author != @current_user

        transaction do
          @question.update published_at: Time.current
          send_notification
          send_notification_to_participatory_space
        end

        broadcast(:ok, @question)
      end

      private

      def send_notification
        return if @question.author.blank?

        Decidim::EventsManager.publish(
          event: "decidim.events.questions.question_published",
          event_class: Decidim::Questions::PublishQuestionEvent,
          resource: @question,
          recipient_ids: @question.author.followers.pluck(:id)
        )
      end

      def send_notification_to_participatory_space
        Decidim::EventsManager.publish(
          event: "decidim.events.questions.question_published",
          event_class: Decidim::Questions::PublishQuestionEvent,
          resource: @question,
          recipient_ids: @question.participatory_space.followers.pluck(:id) - @question.author.followers.pluck(:id),
          extra: {
            participatory_space: true
          }
        )
      end
    end
  end
end
