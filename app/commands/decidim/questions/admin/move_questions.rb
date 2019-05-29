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
          prefix = form.target_component.name[Decidim.config.default_locale.to_s].capitalize[0]

          references = Decidim::Questions::Question.where("reference ~* ?", prefix + '\d+$')
                        .where(component: form.target_component, state: ['evaluating','accepted'])
                        .pluck(:reference)
          references = references.to_a.map do |reference|
            ref = reference.split(prefix).last
            reference = ref =~ /\A\d+\Z/ ? ref.to_i : 0
          end
          references.sort!

          current_index = references.empty? ? 0 : references.last
          current_index = current_index + 1

          transaction do
            questions.each do |question|
              reference = Decidim.reference_generator.call(question, form.target_component)
              if !question.emendation? && %w(evaluating accepted).include?(question.state)
                reference = reference + '-' + prefix + current_index.to_s
                current_index += 1
              end

              Decidim.traceability.update!(
                question,
                @current_user,
                {
                  component: form.target_component,
                  reference: reference
                },
                visibility: "admin-only"
              )
            end
          end
        end

        def manage_custom_references
          prefix = form.target_component.name[Decidim.config.default_locale.to_s].capitalize[0]
          current_ref = Decidim::Questions::Question.where(component: form.target_component, state: ['evaluating','accepted']).order(published_at: :desc).first.reference
          current_index = current_ref.split(prefix).last
          current_index = next_short_ref =~ /\A\d+\Z/ ? next_short_ref.to_i + 1 : 1

          transaction do
            questions.each do |question|
              if !question.emendation? && %w(evaluating accepted).include?(question.state)
                default_ref = Decidim.reference_generator.call(question, form.target_component)
                question.update_column(:reference, default_ref + '-' + prefix + next_short_ref.to_s)
                current_index += 1
              end
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
