# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A command with all the business logic when a user updates a question.
      class UpdateQuestion < Rectify::Command
        include AttachmentMethods
        include HashtagsMethods

        # Public: Initializes the command.
        #
        # form         - A form object with the params.
        # question - the question to update.
        def initialize(form, question)
          @form = form
          @question = question
          @attached_to = question
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
            @question.attachments.destroy_all

            build_attachment
            return broadcast(:invalid) if attachment_invalid?
          end

          transaction do
            update_question
            notify_recipients
            update_answer unless form.answer.blank?
            create_attachment if process_attachments?
          end

          broadcast(:ok, question)
        end

        private

        attr_reader :form, :question, :attachment

        def update_question
          return update_without_versioning unless versioned_attributes_changed?

          update_with_versioning
        end

        def update_answer
          # PaperTrail.request(enabled: false) do
          #   question.update!(
          #     answer: form.answer,
          #     answered_at: Time.current
          #   )
          # end
          answer_question
          notify_followers
          increment_score
        end

        def update_with_versioning
          Decidim.traceability.update!(
            question,
            form.current_user,
            title: title_with_hashtags,
            body: body_with_hashtags,
            category: form.category,
            recipient: form.recipient,
            recipient_ids: form.recipient_ids.compact,
            state: form.state
          )
        end

        def update_without_versioning
          PaperTrail.request(enabled: false) do
            question.update!(
              recipient: form.recipient,
              recipient_ids: form.recipient_ids.compact,
              state: form.state
            )
          end
        end

        # Return true if diff between form and model include versioned attributes
        def versioned_attributes_changed?
          diff = Decidim::Questions::Question::VERSIONED_ATTRIBUTES.map do |attr|
            true if form.send(attr) != question.send(attr)
          end

          diff.include? true
        end

        def notify_recipients
          return if (question.previous_changes.keys & %w[recipient recipient_ids]).empty?

          if %w[evaluating pending].include?(form.state) && form.recipient_ids.any?
            Decidim::EventsManager.publish(
              event: 'decidim.events.questions.forward_question',
              event_class: Decidim::Questions::Admin::ForwardQuestionEvent,
              resource: question,
              affected_users: Decidim::User.where(id: form.recipient_ids).to_a
            )
          end
        end

        def answer_question
          return answer_question_temporary if !form.current_user.admin && participatory_processes_with_role_privileges(:service).present?
          answer_question_permanently
        end

        def answer_question_temporary
          question.update!(
            state: 'pending',
            answer: @form.answer
          )
        end

        def answer_question_permanently
          Decidim.traceability.perform_action!(
            'answer',
            question,
            form.current_user
          ) do
            question.update!(
              state: @form.state,
              answer: @form.answer,
              answered_at: Time.current
            )
          end
        end

        def notify_followers
          return if (question.previous_changes.keys & %w[state]).empty?

          if question.accepted?
            publish_event(
              'decidim.events.questions.question_accepted',
              Decidim::Questions::AcceptedQuestionEvent
            )
          elsif question.rejected?
            publish_event(
              'decidim.events.questions.question_rejected',
              Decidim::Questions::RejectedQuestionEvent
            )
          elsif question.evaluating?
            publish_event(
              'decidim.events.questions.question_evaluating',
              Decidim::Questions::EvaluatingQuestionEvent
            )
          end
        end

        def publish_event(event, event_class)
          Decidim::EventsManager.publish(
            event: event,
            event_class: event_class,
            resource: question,
            affected_users: question.notifiable_identities,
            followers: question.followers - question.notifiable_identities
          )
        end

        def increment_score
          return unless question.accepted?

          question.coauthorships.find_each do |coauthorship|
            if coauthorship.user_group
              Decidim::Gamification.increment_score(coauthorship.user_group, :accepted_questions)
            else
              Decidim::Gamification.increment_score(coauthorship.author, :accepted_questions)
            end
          end
        end

        # Returns a collection of Participatory processes where the given user has the
        # specific role privilege.
        def participatory_processes_with_role_privileges(role)
          Decidim::ParticipatoryProcessesWithUserRole.for(form.current_user, role)
        end
      end
    end
  end
end
