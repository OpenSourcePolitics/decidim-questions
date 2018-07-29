# frozen_string_literal: true

module Decidim
  module Questions
    # A command with all the business logic when a user destroys a draft question.
    class DestroyQuestion < Rectify::Command
      # Public: Initializes the command.
      #
      # question     - The question to destroy.
      # current_user - The current user.
      def initialize(question, current_user)
        @question = question
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid and the question is deleted.
      # - :invalid if the question is not a draft.
      # - :invalid if the question's author is not the current user.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) unless @question.draft?
        return broadcast(:invalid) if @question.author != @current_user

        @question.destroy!

        broadcast(:ok, @question)
      end
    end
  end
end
