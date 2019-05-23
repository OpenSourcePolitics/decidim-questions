# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A command with all the business logic when an admin merges questions from
      # one component to another.
      class MoveQuestions < Rectify::Command
        # Public: Initializes the command.
        #
        # form - A form object with the params.
        def initialize(form, current_user)
          @form = form
          @current_user = current_user
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) unless form.valid?

          move_questions
          notify

          broadcast(:ok, questions)
        end

        private

        attr_reader :form

        def move_questions
          transaction do
            questions.each do |question|
              Decidim.traceability.update!(
                question,
                @current_user,
                { component: form.target_component },
                visibility: "admin-only"
              )
            end
          end
        end

        def questions
          form.questions
        end

        def notify
          questions.each do |question|
            Decidim::EventsManager.publish(
              event: 'decidim.events.questions.moved_question',
              event_class: Decidim::Questions::Admin::MovedQuestionEvent,
              resource: question,
              affected_users: question.notifiable_identities
            ) if question.coauthorships.any?
          end
        end
      end
    end
  end
end
