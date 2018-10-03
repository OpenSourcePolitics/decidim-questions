# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A command with all the business logic when an admin answers a question.
      class AnswerQuestion < Rectify::Command
        # Public: Initializes the command.
        #
        # form - A form object with the params.
        # question - The question to write the answer for.
        def initialize(form, question)
          @form = form
          @question = question
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?

          if question.evaluating? || question.need_moderation?
            forward_question
          elsif question.rejected?
            reject_question
          elsif question.accepted?
            answer_question
            notify_followers
          end

          broadcast(:ok)
        end

        private

        attr_reader :form, :question

        def reject_question
          Rails.logger.debug "==========="
          Rails.logger.debug "Decidim::Questions::Admin::AnswerQuestion.reject_question"
          # Rails.logger.debug permission_action.inspect
          Rails.logger.debug "==========="

          Decidim.traceability.perform_action!(
            "reject",
            question,
            form.current_user
          ) do
            question.update!(
              state: @form.state,
              answer: @form.answer,
              answered_at: Time.current
            )
          end

          Decidim::EventsManager.publish(
            event: "decidim.events.questions.question_rejected",
            event_class: Decidim::Questions::RejectedQuestionEvent,
            resource: question,
            recipient_ids: [@question.author].pluck(:id)
          )

        end

        def forward_question
          Rails.logger.debug "==========="
          Rails.logger.debug "Decidim::Questions::Admin::AnswerQuestion.forward_question"
          # Rails.logger.debug permission_action.inspect
          Rails.logger.debug "==========="

          Decidim.traceability.perform_action!(
            "forward",
            question,
            form.current_user
          ) do
            question.update!(
              state: @form.state,
              recipient_role: @form.recipient_role,
              answered_at: Time.current
            )
          end

          if @form.recipient_role == "service"
            recipients = @question.participatory_space.service_users
          elsif @form.recipient_role == "committer"
            recipients = @question.participatory_space.committee_users
          else
            recipients = @question.participatory_space.moderators
          end

          Decidim::EventsManager.publish(
            event: "decidim.events.questions.evaluating_question_event",
            event_class: Decidim::Questions::EvaluatingQuestionEvent,
            resource: question,
            recipient_ids: recipients
          )

          # Decidim::EventsManager.publish(
          #   event: "decidim.events.questions.question_forward",
          #   event_class: Decidim::Questions::ForwardQuestionEvent,
          #   resource: question,
          #   recipient_ids: [@question.author].pluck(:id)
          # )
        end

        def answer_question
          Rails.logger.debug "==========="
          Rails.logger.debug "Decidim::Questions::Admin::AnswerQuestion.answer_question"
          # Rails.logger.debug permission_action.inspect
          Rails.logger.debug "==========="

          if question.question_type == "question"
            Decidim.traceability.perform_action!(
              "answer",
              question,
              form.current_user
            ) do
              question.update!(
                state: @form.state,
                answer: @form.answer,
                answered_at: Time.current
              )
            end
            # Notify followers
            # Notify author
          else
            Decidim.traceability.perform_action!(
              "answer",
              question,
              form.current_user
            ) do
              question.update!(
                state: @form.state,
                answered_at: Time.current
              )
            end
            # Notify followers
            # Notify author
          end


        end

        def notify_followers
          Rails.logger.debug "==========="
          Rails.logger.debug "Decidim::Questions::Admin::AnswerQuestion.notify_followers"
          # Rails.logger.debug permission_action.inspect
          Rails.logger.debug "==========="

          return if (question.previous_changes.keys & %w(state)).empty?

          recipients = question.followers.pluck(:id)

          if question.accepted?
            publish_event(
              "decidim.events.questions.question_accepted",
              Decidim::Questions::AcceptedQuestionEvent,
              recipients
            )
          elsif question.rejected?
            publish_event(
              "decidim.events.questions.question_rejected",
              Decidim::Questions::RejectedQuestionEvent,
              recipients
            )
          elsif question.evaluating?
            publish_event(
              "decidim.events.questions.question_evaluating",
              Decidim::Questions::EvaluatingQuestionEvent,
              recipients
            )
          end
        end

        def publish_event(event, event_class, recipients)
          Rails.logger.debug "==========="
          Rails.logger.debug "Decidim::Questions::Admin::AnswerQuestion.publish_event"
          # Rails.logger.debug permission_action.inspect
          Rails.logger.debug "==========="

          Decidim::EventsManager.publish(
            event: event,
            event_class: event_class,
            resource: question,
            recipient_ids: recipients
          )
        end

      end
    end
  end
end
