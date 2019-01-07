# frozen_string_literal: true

module Decidim
  module Questions
    # A command with all the business logic when a user withdraws a new question.
    class WithdrawQuestion < Rectify::Command
      # Public: Initializes the command.
      #
      # question     - The question to withdraw.
      # current_user - The current user.
      def initialize(question, current_user)
        @question = question
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the question.
      # - :invalid if the question already has supports or does not belong to current user.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if @question.votes.any?

        transaction do
          change_question_state_to_withdrawn
          reject_emendations_if_any
        end

        broadcast(:ok, @question)
      end

      private

      def change_question_state_to_withdrawn
        @question.update state: "withdrawn"
      end

      def reject_emendations_if_any
        return if @question.emendations.empty?

        @question.emendations.each do |emendation|
          @form = form(Decidim::Amendable::RejectForm).from_params(id: emendation.amendment.id)
          result = Decidim::Amendable::Reject.call(@form)
          return result[:ok] if result[:ok]
        end
      end
    end
  end
end
