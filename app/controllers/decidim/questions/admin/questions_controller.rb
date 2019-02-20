# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # This controller allows admins to manage questions in a participatory process.
      class QuestionsController < Admin::ApplicationController
        include Decidim::ApplicationHelper

        helper Questions::ApplicationHelper
        helper_method :questions, :query, :form_presenter

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
          @form.state = 'evaluating' if question.try(:state).blank?
          @form.recipient = 'none' if question.try(:recipient).blank? && @form.state == 'evaluating'
          @form.attachment = form(AttachmentForm).from_params({})
        end

        def update
          enforce_permission_to :edit, :question, question: question

          @form = form(Admin::QuestionForm).from_params(params)
          Admin::UpdateQuestion.call(@form, @question) do
            on(:ok) do |_question|
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
          @query ||= if current_component.settings.participatory_texts_enabled?
                       Question.where(component: current_component).published.order(:position).ransack(params[:q])
                     else
                       Question.where(component: current_component).published.ransack(params[:q])
                     end
        end

        def query_with_role
          @query ||= if current_component.settings.participatory_texts_enabled?
                       Question.where(component: current_component)
                               .where(recipient: user_role.role)
                               .published
                               .order(:position).ransack(params[:q])
                     else
                       Question.where(component: current_component)
                               .where(recipient: user_role.role)
                               .published
                               .ransack(params[:q])
                     end
        end

        def user_role
          Decidim::ParticipatoryProcessUserRole.includes(:user)
                                               .where(participatory_process: current_participatory_space)
                                               .where(user: current_user)
                                               .first
        end

        def questions
          @questions ||= if user_role
                           query_with_role.result.page(params[:page]).per(15)
                         else
                           query.result.page(params[:page]).per(15)
                         end
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
