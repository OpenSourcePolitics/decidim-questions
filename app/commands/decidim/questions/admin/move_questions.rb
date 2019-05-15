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

          broadcast(:ok, move_questions)
        end

        private

        attr_reader :form

        def move_questions
          transaction do
            form.questions.each do |question|
              question.update!(component: form.target_component)
            end
          end
        end
      end
    end
  end
end
