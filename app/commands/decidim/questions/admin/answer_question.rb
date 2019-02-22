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

          answer_question
          notify_followers
          increment_score

          broadcast(:ok)
        end

        private

        attr_reader :form, :question

        def answer_question
          return answer_question_temporary if can_manage_process?(role: :service)
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

        # Whether the user can manage the given process or not.
        def can_manage_process?(role: :any)
          return unless form.current_user
          return true if form.current_user.admin?

          participatory_processes_with_role_privileges(role).include? form.current_participatory_space
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
