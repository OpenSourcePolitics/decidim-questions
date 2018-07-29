# frozen_string_literal: true

module Decidim
  module Questions
    # A command with all the business logic when a user votes a question.
    class VoteQuestion < Rectify::Command
      # Public: Initializes the command.
      #
      # question     - A Decidim::Questions::Question object.
      # current_user - The current user.
      def initialize(question, current_user)
        @question = question
        @current_user = current_user
        @weight = weight
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the question vote.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if @question.maximum_votes_reached? && !@question.can_accumulate_supports_beyond_threshold

        build_question_vote
        return broadcast(:invalid) unless vote.valid?

        vote.save!
        broadcast(:ok, vote)
      end

      attr_reader :vote

      private

      def build_question_vote
        @vote = @question.votes.build(author: @current_user)
        @vote.update_attributes!(weight: @weight)
      end
    end
  end
end
