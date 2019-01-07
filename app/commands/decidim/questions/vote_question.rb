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

        ActiveRecord::Base.transaction do
          vote.save!
          update_temporary_votes
        end

        Decidim::Gamification.increment_score(@current_user, :question_votes)

        broadcast(:ok, vote)
      end

      attr_reader :vote

      private

      def component
        @component ||= @question.component
      end

      def minimum_votes_per_user
        component.settings.minimum_votes_per_user
      end

      def minimum_votes_per_user?
        minimum_votes_per_user.positive?
      end

      def update_temporary_votes
        return unless minimum_votes_per_user? && user_votes.count >= minimum_votes_per_user
        user_votes.each { |vote| vote.update(temporary: false) }
      end

      def user_votes
        @user_votes ||= QuestionVote.where(
          author: @current_user,
          question: Question.where(component: component)
        )
      end

      def build_question_vote
        @vote = @question.votes.build(
          author: @current_user,
          temporary: minimum_votes_per_user?
        )
      end
    end
  end
end
