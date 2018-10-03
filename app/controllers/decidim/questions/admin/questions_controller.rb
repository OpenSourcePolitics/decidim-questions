# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # This controller allows admins to manage questions in a participatory process.
      class QuestionsController < Admin::ApplicationController
        helper Questions::ApplicationHelper
        helper_method :questions, :query, :current_user_role, :admin_creation_is_enabled?

        def index
          enforce_permission_to :read, :question
          @current_tab = params[:tab] || default_tab
          @tabs = ["todo","ongoing","done"]
        end

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

        def default_tab
          if current_user_role != 'collaborator'
            @current_tab = "todo"
          else
            @current_tab = "done"
          end
        end

        def query
          @search = Question.where(component: current_component).published

          case @current_tab
          when "done"
            @search = @search.where(state: ["accepted","rejected"])
          when "ongoing"
            @search = @search.where(state: ["evaluating","validating"], question_type: "question")
          when "todo"
            if ["service","committee"].include?(current_user_role)
              @search = @search.where(state: ["evaluating"], question_type: "question", recipient_role: current_user_role)
            else # admins & moderators
              @search = @search.where(state: [nil,"need_moderation"])
            end

          end

          @search = @search.ransack(params[:q])
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

        def current_user_role
          return "admin" if current_user.admin
          ParticipatoryProcessUserRole.where(user: current_user, participatory_process: current_participatory_space).first.role
        end

        def admin_creation_is_enabled?
          current_settings.try(:creation_enabled?) &&
            component_settings.try(:official_questions_enabled)
        end
      end
    end
  end
end
