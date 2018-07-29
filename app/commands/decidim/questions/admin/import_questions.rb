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

            origin_attributes = original_question.attributes.except(
              "id",
              "created_at",
              "updated_at",
              "state",
              "answer",
              "answered_at",
              "decidim_component_id",
              "reference",
              "question_votes_count",
              "question_notes_count"
            )

            question = Decidim::Questions::Question.new(origin_attributes)
            question.category = original_question.category
            question.component = target_component
            question.save!

            question.link_resources([original_question], "copied_from_component")
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
