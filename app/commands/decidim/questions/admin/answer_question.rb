# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A command with all the business logic when an admin answers a question.
      class AnswerQuestion < Rectify::Command
        include ReferenceMethods
        # Public: Initializes the command.
        #
        # form - A form object with the params.
        # question - The question to write the answer for.
        def initialize(form, question)
          @form = form
          @question = question
          @is_update = question.try(:state) == 'pending'
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) if form.invalid?

          manage_custom_reference
          answer_question
          increment_score

          broadcast(:ok)
        end

        private

        attr_reader :form, :question

        def answer_question
          return answer_question_temporary if !(form.current_user.admin || participatory_processes_with_role_privileges(:admin).present?)
          answer_question_permanently
        end

        def answer_question_temporary
          question.update!(
            state: 'pending',
            answer: @form.answer
          )
          notify_workflow
        end

        def notify_workflow
          return unless question.state == 'pending'

          recipients = []
          recipients_info = {}

          admin_list = Decidim::ParticipatoryProcessUserRole.where(participatory_process: form.current_participatory_space, role: :admin ).pluck(:decidim_user_id)
          admin_list += form.current_organization.admins.pluck(:id)

          if question.try(:recipient) == 'committee'
            workflow_event = 'decidim.events.questions.question_answered_committee'
          else
            if @is_update
              workflow_event = 'decidim.events.questions.question_answer_updated'
            else
              workflow_event = 'decidim.events.questions.question_answered'
            end
            committee_list = Decidim::ParticipatoryProcessUserRole.where(participatory_process: form.current_participatory_space, role: :committee ).pluck(:decidim_user_id)
            unless committee_list.empty?
              Decidim::EventsManager.publish(
                event: workflow_event + ".committee",
                event_class: Decidim::Questions::Admin::QuestionAnsweredEvent,
                resource: question,
                affected_users: Decidim::User.where(id: committee_list).to_a
              )
            end
          end

          unless admin_list.empty?
            Decidim::EventsManager.publish(
              event: workflow_event + ".admin",
              event_class: Decidim::Questions::Admin::QuestionAnsweredEvent,
              resource: question,
              affected_users: Decidim::User.where(id: admin_list).to_a
            )
          end
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
                answered_at: Time.current,
                first_interacted_at: first_interacted_at
            )
          end
          notify_followers
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

        # Update the publish date when evaluating or accepted
        def first_interacted_at
          return question.first_interacted_at unless question.first_interacted_at.nil?
          return Time.current if question.state != form.state && %w(accepted evaluating).include?(form.state)

          question.first_interacted_at
        end
      end
    end
  end
end
