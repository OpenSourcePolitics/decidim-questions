# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A command with all the business logic when an admin imports questions from
      # a participatory text.
      class PublishParticipatoryText < Rectify::Command
        # Public: Initializes the command.
        #
        # form - A PreviewParticipatoryTextForm form object with the params.
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
          transaction do
            @publish_failures = {}
            update_contents_and_resort_questions(form)
            publish_drafts
          end

          if @publish_failures.any?
            broadcast(:invalid, @publish_failures)
          else
            broadcast(:ok)
          end
        end

        private

        attr_reader :form

        def update_contents_and_resort_questions(form)
          form.questions.each do |prop_form|
            question = Decidim::Questions::Question.where(component: form.current_component).find(prop_form.id)
            question.set_list_position(prop_form.position) if question.position != prop_form.position
            question.title = prop_form.title
            question.body = prop_form.body if question.participatory_text_level == Decidim::Questions::ParticipatoryTextSection::LEVELS[:article]

            add_failure(question) unless question.save
          end
          raise ActiveRecord::Rollback if @publish_failures.any?
        end

        def publish_drafts
          Decidim::Questions::Question.where(component: form.current_component).drafts.find_each do |question|
            add_failure(question) unless question.update(published_at: Time.current)
          end
          raise ActiveRecord::Rollback if @publish_failures.any?
        end

        def add_failure(question)
          @publish_failures[question.id] = question.errors.full_messages
        end
      end
    end
  end
end
