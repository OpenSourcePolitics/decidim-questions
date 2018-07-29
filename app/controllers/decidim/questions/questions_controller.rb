# frozen_string_literal: true

module Decidim
  module Questions
    # Exposes the question resource so users can view and create them.
    class QuestionsController < Decidim::Questions::ApplicationController
      helper Decidim::WidgetUrlsHelper
      helper QuestionWizardHelper
      include FormFactory
      include FilterResource
      include Orderable
      include Paginable

      helper_method :geocoded_questions
      before_action :authenticate_user!, only: [:new, :create, :complete]
      before_action :ensure_is_draft, only: [:preview, :publish, :edit_draft, :update_draft, :destroy_draft]

      def index
        @questions = search
                      .results
                      .published
                      .not_hidden
                      .includes(:author)
                      .includes(:category)
                      .includes(:scope)

        @voted_questions = if current_user
                             QuestionVote.where(
                               author: current_user,
                               question: @questions.pluck(:id)
                             ).pluck(:decidim_question_id)
                           else
                             []
                           end

        @questions = paginate(@questions)
        @questions = reorder(@questions)
      end

      def show
        @question = Question
                    .published
                    .not_hidden
                    .where(component: current_component)
                    .find(params[:id])
        @report_form = form(Decidim::ReportForm).from_params(reason: "spam")
      end

      def new
        enforce_permission_to :create, :question
        @step = :step_1
        if question_draft.present?
          redirect_to edit_draft_question_path(question_draft, component_id: question_draft.component.id, question_slug: question_draft.component.participatory_space.slug)
        else
          @form = form(QuestionForm).from_params(params)
        end
      end

      def create
        enforce_permission_to :create, :question
        @step = :step_3
        @form = form(QuestionForm).from_params(params)

        CreateQuestion.call(@form, current_user) do
          on(:ok) do |question|
            flash[:notice] = I18n.t("questions.create.success", scope: "decidim")

            compare_path = Decidim::ResourceLocatorPresenter.new(question).path + "/preview"
            redirect_to compare_path
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("questions.create.error", scope: "decidim")
            render :complete
          end
        end
      end

      def compare
        @step = :step_2
        @similar_questions ||= Decidim::Questions::SimilarQuestions
                               .for(current_component, params[:question])
                               .all
        @form = form(QuestionForm).from_params(params)

        if @similar_questions.blank?
          flash[:notice] = I18n.t("questions.questions.compare.no_similars_found", scope: "decidim")
          redirect_to complete_questions_path(question: {
            title: @form.title,
            body: @form.body,
            question_type: @form.question_type
          })
        end
      end

      def complete
        enforce_permission_to :create, :question
        @step = :step_3

        if params[:question].present?
          params[:question][:attachment] = form(AttachmentForm).from_params({})
          @form = form(QuestionForm).from_params(params)
        else
          @form = form(QuestionForm).from_params(
            attachment: form(AttachmentForm).from_params({})
          )
        end
      end

      def preview
        @step = :step_4
      end

      def publish
        @step = :step_4
        PublishQuestion.call(@question, current_user) do
          on(:ok) do
            flash[:notice] = I18n.t("questions.publish.success", scope: "decidim")
            redirect_to question_path(@question)
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("questions.publish.error", scope: "decidim")
            render :edit_draft
          end
        end
      end

      def edit_draft
        @step = :step_3
        enforce_permission_to :edit, :question, question: @question

        @form = form(QuestionForm).from_model(@question)
      end

      def update_draft
        @step = :step_1
        enforce_permission_to :edit, :question, question: @question

        @form = form(QuestionForm).from_params(params)
        UpdateQuestion.call(@form, current_user, @question) do
          on(:ok) do |question|
            flash[:notice] = I18n.t("questions.update_draft.success", scope: "decidim")
            redirect_to Decidim::ResourceLocatorPresenter.new(question).path + "/preview"
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("questions.update_draft.error", scope: "decidim")
            render :edit_draft
          end
        end
      end

      def destroy_draft
        enforce_permission_to :edit, :question, question: @question

        DestroyQuestion.call(@question, current_user) do
          on(:ok) do
            flash[:notice] = I18n.t("questions.destroy_draft.success", scope: "decidim")
            redirect_to new_question_path
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("questions.destroy_draft.error", scope: "decidim")
            render :edit_draft
          end
        end
      end

      def edit
        @question = Question.published.not_hidden.where(component: current_component).find(params[:id])
        enforce_permission_to :edit, :question, question: @question

        @form = form(QuestionForm).from_model(@question)
      end

      def update
        @question = Question.not_hidden.where(component: current_component).find(params[:id])
        enforce_permission_to :edit, :question, question: @question

        @form = form(QuestionForm).from_params(params)
        UpdateQuestion.call(@form, current_user, @question) do
          on(:ok) do |question|
            flash[:notice] = I18n.t("questions.update.success", scope: "decidim")
            redirect_to Decidim::ResourceLocatorPresenter.new(question).path
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("questions.update.error", scope: "decidim")
            render :edit
          end
        end
      end

      def withdraw
        @question = Question.published.not_hidden.where(component: current_component).find(params[:id])
        enforce_permission_to :withdraw, :question, question: @question

        WithdrawQuestion.call(@question, current_user) do
          on(:ok) do |_question|
            flash[:notice] = I18n.t("questions.update.success", scope: "decidim")
            redirect_to Decidim::ResourceLocatorPresenter.new(@question).path
          end
          on(:invalid) do
            flash[:alert] = I18n.t("questions.update.error", scope: "decidim")
            redirect_to Decidim::ResourceLocatorPresenter.new(@question).path
          end
        end
      end

      private

      def geocoded_questions
        @geocoded_questions ||= search.results.not_hidden.select(&:geocoded?)
      end

      def search_klass
        QuestionSearch
      end

      def default_filter_params
        {
          search_text: "",
          origin: "all",
          activity: "",
          category_id: "",
          state: "except_rejected",
          scope_id: nil,
          related_to: ""
        }
      end

      def question_draft
        Question.not_hidden.where(component: current_component, author: current_user).find_by(published_at: nil)
      end

      def ensure_is_draft
        @question = Question.not_hidden.where(component: current_component).find(params[:id])
        redirect_to Decidim::ResourceLocatorPresenter.new(@question).path unless @question.draft?
      end
    end
  end
end
