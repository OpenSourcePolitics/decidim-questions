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

      # This will be the PaperTrail version that is
      # shown in the version control feature (1 of 1)
      #
      # For an attribute to appear in the new version it has to be reset
      # and reassigned, as PaperTrail only keeps track of object CHANGES.
      def publish_question
        title = reset(:title)
        body = reset(:body)

        Decidim.traceability.perform_action!(
          "publish",
          @question,
          @current_user,
          visibility: "public-only"
        ) do
          @question.update title: title, body: body, published_at: Time.current
        end
      end

      # Reset the attribute to an empty string and return the old value
      def reset(attribute)
        attribute_value = @question[attribute]
        PaperTrail.request(enabled: false) do
          # rubocop:disable Rails/SkipsModelValidations
          @question.update_attribute attribute, ""
          # rubocop:enable Rails/SkipsModelValidations
        end
        attribute_value
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
