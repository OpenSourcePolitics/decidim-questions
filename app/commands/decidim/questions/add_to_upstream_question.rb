# frozen_string_literal: true

module Decidim
  module Questions
    class AddToUpstreamQuestion < Rectify::Command
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
          @question.add_to_upstream_moderation
          @question.update(
            title: reset(:title),
            body: reset(:body),
            published_at: Time.current
          )
        end

        broadcast(:ok, @question)
      end

      private

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
    end
  end
end
