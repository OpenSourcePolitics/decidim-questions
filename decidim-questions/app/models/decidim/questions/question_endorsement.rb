# frozen_string_literal: true

module Decidim
  module Questions
    # A question can include an endorsement per user or group.
    class QuestionEndorsement < ApplicationRecord
      include Decidim::Authorable

      belongs_to :question, foreign_key: "decidim_question_id", class_name: "Decidim::Questions::Question", counter_cache: true

      validates :question, uniqueness: { scope: [:author, :user_group] }
      validate :author_and_question_same_organization
      validate :question_not_rejected

      scope :for_listing, -> { order(:decidim_user_group_id, :created_at) }

      private

      def organization
        question&.component&.organization
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
