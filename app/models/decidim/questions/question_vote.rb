# frozen_string_literal: true

module Decidim
  module Questions
    # A question can include a vote per user.
    class QuestionVote < ApplicationRecord
      belongs_to :question, foreign_key: "decidim_question_id", class_name: "Decidim::Questions::Question"
      belongs_to :author, foreign_key: "decidim_author_id", class_name: "Decidim::User"

      validates :question, uniqueness: { scope: :author }
      validate :author_and_question_same_organization
      validate :question_not_rejected

      after_save :update_question_votes_count
      after_destroy :update_question_votes_count

      # Temporary votes are used when a minimum amount of votes is configured in
      # a component. They aren't taken into account unless the amount of votes
      # exceeds a threshold - meanwhile, they're marked as temporary.
      def self.temporary
        where(temporary: true)
      end

      # Final votes are votes that will be taken into account, that is, they're
      # not temporary.
      def self.final
        where(temporary: false)
      end

      private

      def update_question_votes_count
        question.update_votes_count
      end

      # Private: check if the question and the author have the same organization
      def author_and_question_same_organization
        return if !question || !author
        errors.add(:question, :invalid) unless author.organization == question.organization
      end

      def question_not_rejected
        return unless question
        errors.add(:question, :invalid) if question.rejected?
      end
    end
  end
end
