# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # This controller allows admins to answer questions in a participatory process.
      class QuestionAnswersController < Admin::ApplicationController
        helper_method :question

        def edit
          enforce_permission_to :create, :question_answer
          @form = form(Admin::QuestionAnswerForm).from_model(question)
        end

        def update
          enforce_permission_to :create, :question_answer
          @form = form(Admin::QuestionAnswerForm).from_params(params)

          Admin::AnswerQuestion.call(@form, question) do
            on(:ok) do
              flash[:notice] = I18n.t("questions.answer.success", scope: "decidim.questions.admin")
              redirect_to questions_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("questions.answer.invalid", scope: "decidim.questions.admin")
              render action: "edit"
            end
          end
        end

        private

        def question
          @question ||= Question.where(component: current_component).find(params[:id])
        end
      end
    end
  end
end
