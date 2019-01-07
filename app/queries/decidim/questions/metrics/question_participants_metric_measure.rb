# frozen_string_literal: true

module Decidim
  module Questions
    module Metrics
      # Searches for Participants in the following actions
      #  - Create a question (Questions)
      #  - Give support to a question (Questions)
      #  - Endorse (Questions)
      class QuestionParticipantsMetricMeasure < Decidim::MetricMeasure
        def valid?
          super && @resource.is_a?(Decidim::Component)
        end

        def calculate
          cumulative_users = []
          cumulative_users |= retrieve_votes.pluck(:decidim_author_id)
          cumulative_users |= retrieve_endorsements.pluck(:decidim_author_id)
          cumulative_users |= retrieve_questions.pluck("decidim_coauthorships.decidim_author_id") # To avoid ambiguosity must be called this way

          quantity_users = []
          quantity_users |= retrieve_votes(true).pluck(:decidim_author_id)
          quantity_users |= retrieve_endorsements(true).pluck(:decidim_author_id)
          quantity_users |= retrieve_questions(true).pluck("decidim_coauthorships.decidim_author_id") # To avoid ambiguosity must be called this way

          {
            cumulative_users: cumulative_users.uniq,
            quantity_users: quantity_users.uniq
          }
        end

        private

        def retrieve_questions(from_start = false)
          @questions ||= Decidim::Questions::Question.where(component: @resource).joins(:coauthorships)
                                                     .includes(:votes, :endorsements)
                                                     .where(decidim_coauthorships: { decidim_author_type: "Decidim::UserBaseEntity" })
                                                     .where("decidim_questions_questions.published_at <= ?", end_time)
                                                     .except_withdrawn

          return @questions.where("decidim_questions_questions.published_at >= ?", start_time) if from_start
          @questions
        end

        def retrieve_votes(from_start = false)
          @votes ||= Decidim::Questions::QuestionVote.joins(:question).where(question: retrieve_questions).joins(:author)
                                                     .where("decidim_questions_question_votes.created_at <= ?", end_time)

          return @votes.where("decidim_questions_question_votes.created_at >= ?", start_time) if from_start
          @votes
        end

        def retrieve_endorsements(from_start = false)
          @endorsements ||= Decidim::Questions::QuestionEndorsement.joins(:question).where(question: retrieve_questions)
                                                                   .where("decidim_questions_question_endorsements.created_at <= ?", end_time)
                                                                   .where(decidim_author_type: "Decidim::UserBaseEntity")

          return @endorsements.where("decidim_questions_question_endorsements.created_at >= ?", start_time) if from_start
          @endorsements
        end
      end
    end
  end
end
