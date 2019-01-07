# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A command with all the business logic when a user creates a new question.
      class CreateQuestion < Rectify::Command
        include HashtagsMethods

        # Public: Initializes the command.
        #
        # form - A form object with the params.
        def initialize(form)
          @form = form
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid, together with the question.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?

          if process_attachments?
            build_attachment
            return broadcast(:invalid) if attachment_invalid?
          end

          transaction do
            create_question
            create_attachment if process_attachments?
            send_notification
          end

          broadcast(:ok, question)
        end

        private

        attr_reader :form, :question, :attachment

        def create_question
          @question = Decidim::Questions::QuestionBuilder.create(
            attributes: attributes,
            author: form.author,
            action_user: form.current_user
          )
        end

        def attributes
          {
            title: title_with_hashtags,
            body: body_with_hashtags,
            category: form.category,
            scope: form.scope,
            component: form.component,
            address: form.address,
            latitude: form.latitude,
            longitude: form.longitude,
            created_in_meeting: form.created_in_meeting,
            published_at: Time.current
          }
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

        def send_notification
          Decidim::EventsManager.publish(
            event: "decidim.events.questions.question_published",
            event_class: Decidim::Questions::PublishQuestionEvent,
            resource: question,
            followers: @question.participatory_space.followers,
            extra: {
              participatory_space: true
            }
          )
        end
      end
    end
  end
end
