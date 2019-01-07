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
        return broadcast(:invalid) unless @question.authored_by?(@current_user)

        transaction do
          publish_question
          increment_scores
          send_notification
          send_notification_to_participatory_space
        end

        broadcast(:ok, @question)
      end

      private

      # Prevent PaperTrail from creating an additional version
      # in the question multi-step creation process (step 4: publish)
      def publish_question
        PaperTrail.request(enabled: false) do
          @question.update published_at: Time.current
        end
      end

      def send_notification
        return if @question.coauthorships.empty?

        Decidim::EventsManager.publish(
          event: "decidim.events.questions.question_published",
          event_class: Decidim::Questions::PublishQuestionEvent,
          resource: @question,
          followers: coauthors_followers
        )
      end

      def send_notification_to_participatory_space
        Decidim::EventsManager.publish(
          event: "decidim.events.questions.question_published",
          event_class: Decidim::Questions::PublishQuestionEvent,
          resource: @question,
          followers: @question.participatory_space.followers - coauthors_followers,
          extra: {
            participatory_space: true
          }
        )
      end

      def coauthors_followers
        @coauthors_followers ||= @question.authors.flat_map(&:followers)
      end

      def increment_scores
        @question.coauthorships.find_each do |coauthorship|
          if coauthorship.user_group
            Decidim::Gamification.increment_score(coauthorship.user_group, :questions)
          else
            Decidim::Gamification.increment_score(coauthorship.author, :questions)
          end
        end
      end
    end
  end
end
