# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A command with all the business logic when an admin splits questions from
      # one component to another.
      class SplitQuestions < Rectify::Command
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

          broadcast(:ok, split_questions)
        end

        private

        attr_reader :form

        def split_questions
          transaction do
            form.questions.flat_map do |original_question|
              # If copying to the same component we only need one copy
              # but linking to the original question links, not the
              # original question.
              create_question(original_question)
              create_question(original_question) unless form.same_component?
            end
          end
        end

        def create_question(original_question)
          split_question = Decidim::Questions::QuestionBuilder.copy(
            original_question,
            author: form.current_organization,
            action_user: form.current_user,
            extra_attributes: {
              component: form.target_component
            },
            skip_link: true
          )

          questions_to_link = links_for(original_question)
          split_question.link_resources(questions_to_link, "copied_from_component")
        end

        def links_for(question)
          return question unless form.same_component?

          question.linked_resources(:questions, "copied_from_component")
        end
      end
    end
  end
end
