# frozen_string_literal: true

module Decidim
  module Questions
    # Exposes the question resource so users can view and create them.
    class QuestionsController < Decidim::Questions::ApplicationController
      helper Decidim::WidgetUrlsHelper
      helper QuestionWizardHelper
      helper ParticipatoryTextsHelper
      include Decidim::ApplicationHelper
      include FormFactory
      include FilterResource
      include Orderable
      include Paginable

      helper_method :form_presenter

      before_action :authenticate_user!, only: [:new, :create, :complete]
      before_action :ensure_is_draft, only: [:compare, :complete, :preview, :publish, :edit_draft, :update_draft, :destroy_draft]
      before_action :set_question, only: [:show, :edit, :update, :withdraw]
      before_action :edit_form, only: [:edit_draft, :edit]

      before_action :set_participatory_text

      def index
        if component_settings.participatory_texts_enabled?
          @questions = Decidim::Questions::Question
                       .where(component: current_component)
                       .published
                       .not_hidden
                       .includes(:category, :scope)
                       .order(position: :asc)
          render "decidim/questions/questions/participatory_texts/participatory_text"
        else
          @questions = search
                       .results
                       .published
                       .state_visible
                       .not_hidden
                       .upstream_not_hidden
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
      end

      def show
        enforce_permission_to :show, :question, question: @question
        @report_form = form(Decidim::ReportForm).from_params(reason: "spam")
      end

      def new
        enforce_permission_to :create, :question
        @step = :step_1
        if question_draft.present?
          redirect_to edit_draft_question_path(question_draft, component_id: question_draft.component.id, question_slug: question_draft.component.participatory_space.slug)
        else
          @form = form(QuestionWizardCreateStepForm).from_params({})
        end
      end

      def create
        enforce_permission_to :create, :question
        @step = :step_1
        @form = form(QuestionWizardCreateStepForm).from_params(params)

        CreateQuestion.call(@form, current_user) do
          on(:ok) do |question|
            flash[:notice] = I18n.t("questions.create.success", scope: "decidim")

            redirect_to Decidim::ResourceLocatorPresenter.new(question).path + "/compare"
          end

          on(:invalid) do
            flash.now[:alert] = I18n.t("questions.create.error", scope: "decidim")
            render :new
          end
        end
      end

      def compare
        @step = :step_2
        @similar_questions ||= Decidim::Questions::SimilarQuestions
                               .for(current_component, @question)
                               .all

        if @similar_questions.blank?
          flash[:notice] = I18n.t("questions.questions.compare.no_similars_found", scope: "decidim")
          redirect_to Decidim::ResourceLocatorPresenter.new(@question).path + "/complete"
        end
      end

      def complete
        enforce_permission_to :create, :question
        @step = :step_3

        @form = form_question_model

        @form.attachment = form_attachment_new
      end

      def preview
        @step = :step_4
      end

      def publish
        @step = :step_4
        publish_command.call(@question, current_user) do
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
      end

      def update_draft
        @step = :step_1
        enforce_permission_to :edit, :question, question: @question

        @form = form_question_params
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
        enforce_permission_to :edit, :question, question: @question
      end

      def update
        enforce_permission_to :edit, :question, question: @question

        @form = form_question_params
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
        enforce_permission_to :withdraw, :question, question: @question
        if @question.emendation?
          Decidim::Amendable::Withdraw.call(@question, current_user) do
            on(:ok) do |_question|
              flash[:notice] = I18n.t("questions.update.success", scope: "decidim")
              redirect_to Decidim::ResourceLocatorPresenter.new(@emendation).path
            end
            on(:invalid) do
              flash[:alert] = I18n.t("questions.update.error", scope: "decidim")
              redirect_to Decidim::ResourceLocatorPresenter.new(@emendation).path
            end
          end
        else
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
      end

      private

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
          related_to: "",
          type: "all"
        }
      end

      def question_draft
        Question.from_all_author_identities(current_user).not_hidden.where(component: current_component).find_by(published_at: nil)
      end

      def ensure_is_draft
        @question = Question.not_hidden.upstream_not_hidden.where(component: current_component).find(params[:id])
        redirect_to Decidim::ResourceLocatorPresenter.new(@question).path unless @question.draft?
      end

      def set_question
        @question = Question.published.not_hidden.where(component: current_component).find(params[:id])
      end

      def form_question_params
        form(QuestionForm).from_params(params)
      end

      def form_question_model
        form(QuestionForm).from_model(@question)
      end

      def form_presenter
        @form_presenter ||= present(@form, presenter_class: Decidim::Questions::QuestionPresenter)
      end

      def form_attachment_new
        form(AttachmentForm).from_params({})
      end

      def edit_form
        form_attachment_model = form(AttachmentForm).from_model(@question.attachments.first)
        @form = form_question_model
        @form.attachment = form_attachment_model
        @form
      end

      def set_participatory_text
        @participatory_text = Decidim::Questions::ParticipatoryText.find_by(component: current_component)
      end

      def publish_command
        return Decidim::Questions::PublishQuestion unless need_moderation?
        Decidim::Questions::AddToUpstreamQuestion
      end

      def need_moderation?
        component_settings.upstream_moderation && !author_has_role?
      end

      def author_has_role?
        !(participatory_space_admins & @question.authors).empty?
      end

      def participatory_space_admins
        @participatory_space_admins ||= participatory_space.admins
      end

      def participatory_space_moderators
        @participatory_space_moderators ||= participatory_space.moderators
      end

      def participatory_space
        @participatory_space ||= current_component.participatory_space
      end
    end
  end
end
