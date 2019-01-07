# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A command with all the business logic when an admin imports questions from
      # one component to another.
      class ImportQuestions < Rectify::Command
        # Public: Initializes the command.
        #
        # form - A form object with the params.
        def initialize(form)
          @form = form
        end

        # Executes the command. Broadcasts these events:
        #
        # - :ok when everything is valid.
        # - :invalid if the form wasn't valid and we couldn't proceed.
        #
        # Returns nothing.
        def call
          return broadcast(:invalid) unless form.valid?

          broadcast(:ok, import_questions)
        end

        private

        attr_reader :form

        def import_questions
          questions.map do |original_question|
            next if question_already_copied?(original_question, target_component)

            Decidim::Questions::QuestionBuilder.copy(
              original_question,
              author: form.current_organization,
              action_user: form.current_user,
              extra_attributes: {
                "component" => target_component
              }
            )
          end.compact
        end

        def questions
          Decidim::Questions::Question
            .where(component: origin_component)
            .where(state: question_states)
        end

        def question_states
          @question_states = @form.states

          if @form.states.include?("not_answered")
            @question_states.delete("not_answered")
            @question_states.push(nil)
          end

          @question_states
        end

        def origin_component
          @form.origin_component
        end

        def target_component
          @form.current_component
        end

        def question_already_copied?(original_question, target_component)
          original_question.linked_resources(:questions, "copied_from_component").any? do |question|
            question.component == target_component
          end
        end
      end
    end
  end
end
