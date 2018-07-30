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
        end

        broadcast(:ok, @question)
      end

      private

      def send_notification # to moderators
        Decidim::EventsManager.publish(
          event: "decidim.events.questions.question_need_moderation",
          event_class: Decidim::Questions::QuestionNeedModerationEvent,
          resource: @question,
          recipient_ids: (@question.users_to_notify_on_question_need_moderation - [@question.author]).pluck(:id),
          extra: {
            # new_content: true,
            # process_slug: @question.participatory_space.slug
          }
        )
      end
    end
  end
end
