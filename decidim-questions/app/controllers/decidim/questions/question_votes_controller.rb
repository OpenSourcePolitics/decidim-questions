# frozen_string_literal: true

module Decidim
  module Questions
    # Exposes the question vote resource so users can vote questions.
    class QuestionVotesController < Decidim::Questions::ApplicationController
      include QuestionVotesHelper
      include Rectify::ControllerHelpers

      helper_method :question

      before_action :authenticate_user!

      def create
        enforce_permission_to :vote, :question, question: question
        @from_questions_list = params[:from_questions_list] == "true"

        VoteQuestion.call(question, current_user) do
          on(:ok) do
            question.reload

            questions = QuestionVote.where(
              author: current_user,
              question: Question.where(component: current_component)
            ).map(&:question)

            expose(questions: questions)
            render :update_buttons_and_counters
          end

          on(:invalid) do
            render json: { error: I18n.t("question_votes.create.error", scope: "decidim.questions") }, status: 422
          end
        end
      end

      def destroy
        enforce_permission_to :unvote, :question, question: question
        @from_questions_list = params[:from_questions_list] == "true"

        UnvoteQuestion.call(question, current_user) do
          on(:ok) do
            question.reload

            questions = QuestionVote.where(
              author: current_user,
              question: Question.where(component: current_component)
            ).map(&:question)

            expose(questions: questions + [question])
            render :update_buttons_and_counters
          end
        end
      end

      private

      def question
        @question ||= Question.where(component: current_component).find(params[:question_id])
      end
    end
  end
end
