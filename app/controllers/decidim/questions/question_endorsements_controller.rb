# frozen_string_literal: true

module Decidim
  module Questions
    # Exposes the question endorsement resource so that users can endorse questions.
    class QuestionEndorsementsController < Decidim::Questions::ApplicationController
      helper_method :question

      before_action :authenticate_user!

      def create
        enforce_permission_to :endorse, :question, question: question
        @from_questions_list = params[:from_questions_list] == "true"
        user_group_id = params[:user_group_id]

        EndorseQuestion.call(question, current_user, user_group_id) do
          on(:ok) do
            question.reload
            render :update_buttons_and_counters
          end

          on(:invalid) do
            render json: { error: I18n.t("question_endorsements.create.error", scope: "decidim.questions") }, status: 422
          end
        end
      end

      def destroy
        enforce_permission_to :unendorse, :question, question: question
        @from_questions_list = params[:from_questions_list] == "true"
        user_group_id = params[:user_group_id]
        user_group = user_groups.find(user_group_id) if user_group_id

        UnendorseQuestion.call(question, current_user, user_group) do
          on(:ok) do
            question.reload
            render :update_buttons_and_counters
          end
        end
      end

      def identities
        enforce_permission_to :endorse, :question, question: question

        @user_verified_groups = Decidim::UserGroups::ManageableUserGroups.for(current_user).verified
        render :identities, layout: false
      end

      private

      def user_groups
        Decidim::UserGroups::ManageableUserGroups.for(current_user).verified
      end

      def question
        @question ||= Question.where(component: current_component).find(params[:question_id])
      end
    end
  end
end
