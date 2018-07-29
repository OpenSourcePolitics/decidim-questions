# frozen_string_literal: true

module Decidim
  module Questions
    # A command with all the business logic when a user or organization unendorses a question.
    class UnendorseQuestion < Rectify::Command
      # Public: Initializes the command.
      #
      # question     - A Decidim::Questions::Question object.
      # current_user - The current user.
      # current_group- (optional) The current_group that is unendorsing from the Question.
      def initialize(question, current_user, current_group = nil)
        @question = question
        @current_user = current_user
        @current_group = current_group
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the question.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        destroy_question_endorsement
        broadcast(:ok, @question)
      end

      private

      def destroy_question_endorsement
        query = @question.endorsements.where(
          author: @current_user,
          decidim_user_group_id: @current_group&.id
        )
        query.destroy_all
      end
    end
  end
end
