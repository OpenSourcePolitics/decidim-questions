# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # This controller allows admins to manage questions in a participatory process.
      class QuestionsController < Admin::ApplicationController
        helper Questions::ApplicationHelper
        helper_method :questions, :query

        def new
          enforce_permission_to :create, :question
          @form = form(Admin::QuestionForm).from_params(
            attachment: form(AttachmentForm).from_params({})
          )
        end

        def create
          enforce_permission_to :create, :question
          @form = form(Admin::QuestionForm).from_params(params)

          Admin::CreateQuestion.call(@form) do
            on(:ok) do
              flash[:notice] = I18n.t("questions.create.success", scope: "decidim.questions.admin")
              redirect_to questions_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("questions.create.invalid", scope: "decidim.questions.admin")
              render action: "new"
            end
          end
        end

        def update_category
          enforce_permission_to :update, :question_category
          @question_ids = params[:question_ids]

          Admin::UpdateQuestionCategory.call(params[:category][:id], params[:question_ids]) do
            on(:invalid_category) do
              flash.now[:error] = I18n.t(
                "questions.update_category.select_a_category",
                scope: "decidim.questions.admin"
              )
            end

            on(:invalid_question_ids) do
              flash.now[:alert] = I18n.t(
                "questions.update_category.select_a_question",
                scope: "decidim.questions.admin"
              )
            end

            on(:update_questions_category) do
              flash.now[:notice] = update_questions_category_response_successful @response
              flash.now[:alert] = update_questions_category_response_errored @response
            end
            respond_to do |format|
              format.js
            end
          end
        end

        private

        def query
          @search = Question.where(component: current_component).published.ransack(params[:q])
          @search.sorts = Questions.default_order_on_admin_index if @search.sorts.empty?
          @query ||= @search
        end

        def questions
          @questions ||= query.result.page(params[:page]).per(15)
        end

        def question
          @question ||= Question.where(component: current_component).find(params[:id])
        end

        def update_questions_category_response_successful(response)
          return if response[:successful].blank?
          I18n.t(
            "questions.update_category.success",
            category: response[:category_name],
            questions: response[:successful].to_sentence,
            scope: "decidim.questions.admin"
          )
        end

        def update_questions_category_response_errored(response)
          return if response[:errored].blank?
          I18n.t(
            "questions.update_category.invalid",
            category: response[:category_name],
            questions: response[:errored].to_sentence,
            scope: "decidim.questions.admin"
          )
        end
      end
    end
  end
end
