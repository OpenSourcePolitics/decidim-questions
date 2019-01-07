# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A command with all the business logic when an admin merges questions from
      # one component to another.
      class MergeQuestions < Rectify::Command
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

          broadcast(:ok, merge_questions)
        end

        private

        attr_reader :form

        def merge_questions
          transaction do
            merged_question = create_new_question
            merged_question.link_resources(questions_to_link, "copied_from_component")
            form.questions.each(&:destroy!) if form.same_component?
            merged_question
          end
        end

        def questions_to_link
          return previous_links if form.same_component?
          form.questions
        end

        def previous_links
          @previous_links ||= form.questions.flat_map do |question|
            question.linked_resources(:questions, "copied_from_component")
          end
        end

        def create_new_question
          original_question = form.questions.first

          Decidim::Questions::QuestionBuilder.copy(
            original_question,
            author: form.current_organization,
            action_user: form.current_user,
            extra_attributes: {
              component: form.target_component
            },
            skip_link: true
          )
        end
      end
    end
  end
end
