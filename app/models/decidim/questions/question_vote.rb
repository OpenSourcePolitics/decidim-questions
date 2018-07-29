# frozen_string_literal: true

module Decidim
  module Questions
    # A question can include a vote per user.
    class QuestionVote < ApplicationRecord
      belongs_to :question, foreign_key: "decidim_question_id", class_name: "Decidim::Questions::Question", counter_cache: true
      belongs_to :author, foreign_key: "decidim_author_id", class_name: "Decidim::User"

      validates :question, uniqueness: { scope: :author }
      validate :author_and_question_same_organization
      validate :question_not_rejected

      def self.create_or_delete(question, current_user, weight)
        if where(author: current_user, question: question, weight: weight).any?
          :delete
        else
          :post
        end
      end

      private

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
