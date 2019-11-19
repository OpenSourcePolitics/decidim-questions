# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A command with all the business logic when a user updates a question.
      class UpdateQuestion < Rectify::Command
        include AttachmentMethods
        include HashtagsMethods
        include ReferenceMethods

        # Public: Initializes the command.
        #
        # form         - A form object with the params.
        # question - the question to update.
        def initialize(form, question)
          @form = form
          @question = question
          @attached_to = question
          @state_changed = (@question.state != @form.state)
          @upstream_notified = []
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid, together with the question.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if @form.invalid?

          if process_attachments?
            @question.attachments.destroy_all

            build_attachment
            return broadcast(:invalid) if attachment_invalid?
          end

          transaction do
            manage_custom_reference
            update_question
            notify_recipients
            manage_upstream_moderation if @question.component.try(:settings).try(:upstream_moderation)
            update_answer if @form.answer.present?
            create_attachment if process_attachments?
          end

          broadcast(:ok, @question)
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
          increment_score
        end

        def update_with_versioning
          Decidim.traceability.update!(
            @question,
            @form.current_user,
            title: title_with_hashtags,
            body: body_with_hashtags,
            reference: @question.reference,
            category: @form.category,
            recipient: @form.recipient,
            recipient_ids: @form.recipient_ids.compact,
            state: @form.state,
            first_interacted_at: first_interacted_at
          )
        end

        def update_without_versioning
          PaperTrail.request(enabled: false) do
            @question.update!(
              reference: @question.reference,
              recipient: @form.recipient,
              recipient_ids: @form.recipient_ids.compact,
              state: @form.state,
              first_interacted_at: first_interacted_at
            )
          end
        end

        # Return true if diff between form and model include versioned attributes
        def versioned_attributes_changed?
          diff = Decidim::Questions::Question::VERSIONED_ATTRIBUTES.map do |attr|
            true if @form.send(attr) != @question.send(attr)
          end

          diff.include? true
        end

        def notify_recipients
          return if !@state_changed && (@question.previous_changes.keys & %w(recipient recipient_ids)).empty?

          if %w(evaluating pending).include?(@form.state) && @form.recipient_ids.any?
            Decidim::EventsManager.publish(
              event: "decidim.events.questions.forward_question",
              event_class: Decidim::Questions::Admin::ForwardQuestionEvent,
              resource: @question,
              affected_users: Decidim::User.where(id: @form.recipient_ids).to_a
            )
          end
        end

        def answer_question
          return answer_question_temporary if !@form.current_user.admin && participatory_processes_with_role_privileges(:service).present?
          answer_question_permanently
        end

        def answer_question_temporary
          @question.update!(
            state: "pending",
            answer: @form.answer
          )
        end

        def answer_question_permanently
          Decidim.traceability.perform_action!(
            "answer",
            @question,
            @form.current_user
          ) do
            @question.update!(
              state: @form.state,
              answer: @form.answer,
              answered_at: Time.current,
              first_interacted_at: first_interacted_at
            )
          end
          notify_followers
        end

        def notify_followers
          return unless @state_changed

          if @question.accepted?
            if @question.component.try(:settings).try(:upstream_moderation) && @question.upstream_pending?
              Decidim.traceability.perform_action!(
                "accept",
                @question.upstream_moderation,
                @form.current_user,
                extra: {
                  upstream_reportable_type: @question.class.name
                }
              ) do
                @question.upstream_moderation.update!(
                  hidden_at: nil,
                  pending: false
                )
              end
            end

            publish_event(
              "decidim.events.questions.question_accepted",
              Decidim::Questions::AcceptedQuestionEvent,
              @question.notifiable_identities,
              @question.followers + Decidim::User.where(id: @form.recipient_ids).to_a - @question.notifiable_identities
            )
          elsif @question.rejected?
            if @question.component.try(:settings).try(:upstream_moderation) && @question.upstream_pending?
              Decidim.traceability.perform_action!(
                "hide",
                @question.upstream_moderation,
                @form.current_user,
                extra: {
                  upstream_reportable_type: @question.class.name
                }
              ) do
                @question.upstream_moderation.update!(
                  hidden_at: Time.current,
                  pending: false
                )
              end
            end

            publish_event(
              "decidim.events.questions.question_rejected",
              Decidim::Questions::RejectedQuestionEvent,
              @question.notifiable_identities,
              @question.followers + Decidim::User.where(id: @form.recipient_ids).to_a - @question.notifiable_identities
            )
          elsif @question.evaluating?
            publish_event(
              "decidim.events.questions.question_evaluating",
              Decidim::Questions::EvaluatingQuestionEvent,
              @question.notifiable_identities - @upstream_notified,
              @question.followers - (Decidim::User.where(id: @form.recipient_ids).to_a + @question.notifiable_identities)
            )
          end
        end

        def publish_event(event, event_class, affected_users, followers)
          Decidim::EventsManager.publish(
            event: event,
            event_class: event_class,
            resource: @question,
            affected_users: affected_users.uniq,
            followers: followers.uniq
          )
        end

        def increment_score
          return unless @question.accepted?

          @question.coauthorships.find_each do |coauthorship|
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
          Decidim::ParticipatoryProcessesWithUserRole.for(@form.current_user, role)
        end

        # Update the publish date when evaluating or accepted
        def first_interacted_at
          return @question.first_interacted_at unless @question.first_interacted_at.nil?
          return Time.current if @question.state != @form.state && %w(accepted evaluating).include?(@form.state)

          @question.first_interacted_at
        end

        def manage_upstream_moderation
          return unless @question.upstream_pending? && @question.state == "evaluating"

          Decidim.traceability.perform_action!(
            "accept",
            @question.upstream_moderation,
            @form.current_user,
            extra: {
              upstream_reportable_type: @question.class.name
            }
          ) do
            @question.upstream_moderation.update!(
              hidden_at: nil,
              pending: false
            )
          end
          Decidim::EventsManager.publish(
            event: "decidim.events.questions.admin.upstream_accepted",
            event_class: Decidim::Questions::Admin::UpstreamAcceptedEvent,
            resource: @question,
            affected_users: @question.authors
          )
          @upstream_notified += @question.authors.kind_of?(Array) ? @question.authors : [@question.authors]
        end
      end
    end
  end
end
