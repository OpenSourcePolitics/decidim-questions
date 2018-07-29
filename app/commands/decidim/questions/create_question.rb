# frozen_string_literal: true

module Decidim
  module Questions
    # A command with all the business logic when a user creates a new question.
    class CreateQuestion < Rectify::Command
      # Public: Initializes the command.
      #
      # form         - A form object with the params.
      # current_user - The current user.
      def initialize(form, current_user)
        @form = form
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the question.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if form.invalid?

        if question_limit_reached?
          form.errors.add(:base, I18n.t("decidim.questions.new.limit_reached"))
          return broadcast(:invalid)
        end

        if process_attachments?
          build_attachment
          return broadcast(:invalid) if attachment_invalid?
        end

        transaction do
          create_question
          create_attachment if process_attachments?
          #create_report!
        end

        #hide!

        broadcast(:ok, question)
      end

      private

      attr_reader :form, :question, :attachment

      def create_question
        @question = Question.create!(
          title: form.title,
          body: form.body,
          question_type: form.question_type,
          category: form.category,
          scope: form.scope,
          author: @current_user,
          decidim_user_group_id: form.user_group_id,
          component: form.component,
          address: form.address,
          latitude: form.latitude,
          longitude: form.longitude
        )
      end

      def build_attachment
        @attachment = Attachment.new(
          title: form.attachment.title,
          file: form.attachment.file,
          attached_to: @question
        )
      end

      def attachment_invalid?
        if attachment.invalid? && attachment.errors.has_key?(:file)
          form.attachment.errors.add :file, attachment.errors[:file]
          true
        end
      end

      def attachment_present?
        form.attachment.file.present?
      end

      def create_attachment
        attachment.attached_to = question
        attachment.save!
      end

      def attachments_allowed?
        form.current_component.settings.attachments_allowed?
      end

      def process_attachments?
        attachments_allowed? && attachment_present?
      end

      def question_limit_reached?
        question_limit = form.current_component.settings.question_limit

        return false if question_limit.zero?

        if user_group
          user_group_questions.count >= question_limit
        else
          current_user_questions.count >= question_limit
        end
      end

      def user_group
        @user_group ||= Decidim::UserGroup.find_by(organization: organization, id: form.user_group_id)
      end

      def organization
        @organization ||= @current_user.organization
      end

      def current_user_questions
        Question.where(author: @current_user, component: form.current_component).except_withdrawn
      end

      def user_group_questions
        Question.where(user_group: @user_group, component: form.current_component).except_withdrawn
      end

      def create_report!
        @moderation = Moderation.find_or_create_by!(
          reportable: @question,
          participatory_space: @question.component.participatory_space
        )
        @report = Report.create!(
          moderation: @moderation,
          user: @current_user,
          reason: "does_not_belong",
          details: form.title
        )
        @moderation.update!(report_count: @moderation.report_count + 1)
      end

      def hide!
        Decidim::Admin::HideResource.new(@question, @current_user).call
      end

      def send_notification #to moderators
        Decidim::EventsManager.publish(
          event: "decidim.events.questions.question_created",
          event_class: Decidim::Questions::QuestionCreatedEvent,
          resource: @question,
          recipient_ids: (@question.users_to_notify_on_question_created - [@question.author]).pluck(:id),
          extra: {
            new_content: true,
            process_slug: @question.feature.participatory_space.slug
          }
        )
      end

    end
  end
end
