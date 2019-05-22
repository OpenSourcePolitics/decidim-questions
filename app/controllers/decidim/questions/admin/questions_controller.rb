# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # This controller allows admins to manage questions in a participatory process.
      class QuestionsController < Admin::ApplicationController
        include Decidim::ApplicationHelper

        helper Questions::ApplicationHelper
        helper_method :questions, :categories, :query, :form_presenter

        delegate :categories, to: :current_component

        def new
          enforce_permission_to :create, :question
          @form = form(Admin::QuestionForm).from_params(
            state: 'evaluating',
            recipient: 'none',
            attachment: form(AttachmentForm).from_params({})
          )
        end

        def create
          enforce_permission_to :create, :question
          @form = form(Admin::QuestionForm).from_params(params)

          Admin::CreateQuestion.call(@form) do
            on(:ok) do
              flash[:notice] = I18n.t('questions.create.success', scope: 'decidim.questions.admin')
              redirect_to questions_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t('questions.create.invalid', scope: 'decidim.questions.admin')
              render action: 'new'
            end
          end
        end

        def update_category
          enforce_permission_to :update, :question_category
          @question_ids = params[:question_ids]

          Admin::UpdateQuestionCategory.call(params[:category][:id], params[:question_ids]) do
            on(:invalid_category) do
              flash.now[:error] = I18n.t(
                'questions.update_category.select_a_category',
                scope: 'decidim.questions.admin'
              )
            end

            on(:invalid_question_ids) do
              flash.now[:alert] = I18n.t(
                'questions.update_category.select_a_question',
                scope: 'decidim.questions.admin'
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

        def edit
          enforce_permission_to :edit, :question
          @form = form(Admin::QuestionForm).from_model(question)
          @form.attachment = form(AttachmentForm).from_params({})
        end

        def update
          enforce_permission_to :edit, :question, question: question

          @form = form(Admin::QuestionForm).from_params(params)
          Admin::UpdateQuestion.call(@form, @question) do
            on(:ok) do |question|
              if question.upstream_pending?
                Decidim.traceability.perform_action!(
                  "accept",
                  question.upstream_moderation,
                  current_user,
                  extra: {
                    upstream_reportable_type: "Decidim::Questions::Question"
                  }
                ) do
                  question.upstream_moderation.update!(
                    hidden_at: nil,
                    pending: false
                  )
                end
              end
              flash[:notice] = I18n.t('questions.update.success', scope: 'decidim')
              redirect_to questions_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t('questions.update.error', scope: 'decidim')
              render :edit
            end
          end
        end

        private

        def query
          return @query if defined?(@query)

          @query = Question.where(component: current_component)
                           .published
                           .not_hidden
                           .upstream_not_hidden_for(user_role)

          @query = @query.where("recipient_ids @> ARRAY[?]", [current_user.id]) if user_role == "service"
          @query = @query.order(:position) if current_component.settings.participatory_texts_enabled?
          @query = @query.ransack(params[:q])
        end

        def user_role
          return "admin" if current_user.admin?

          @user_role ||= Decidim::ParticipatoryProcessUserRole.includes(:user)
                                               .where(participatory_process: current_participatory_space)
                                               .where(user: current_user)
                                               .pluck(:role)
                                               .first
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
            'questions.update_category.success',
            category: response[:category_name],
            questions: response[:successful].to_sentence,
            scope: 'decidim.questions.admin'
          )
        end

        def update_questions_category_response_errored(response)
          return if response[:errored].blank?

          I18n.t(
            'questions.update_category.invalid',
            category: response[:category_name],
            questions: response[:errored].to_sentence,
            scope: 'decidim.questions.admin'
          )
        end

        def form_presenter
          @form_presenter ||= present(@form, presenter_class: Decidim::Questions::QuestionPresenter)
        end
      end
    end
  end
end
