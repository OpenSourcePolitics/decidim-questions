# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A command with all the business logic when an admin imports questions from
      # a participatory text.
      class PublishParticipatoryText < UpdateParticipatoryText
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
            @failures = {}
            update_contents_and_resort_questions(form)
            publish_drafts
          end

          if @failures.any?
            broadcast(:invalid, @failures)
          else
            broadcast(:ok)
          end
        end

        private

        attr_reader :form

        def publish_drafts
          Decidim::Questions::Question.where(component: form.current_component).drafts.find_each do |question|
            add_failure(question) unless question.update(published_at: Time.current)
          end
          raise ActiveRecord::Rollback if @failures.any?
        end

        def add_failure(question)
          @failures[question.id] = question.errors.full_messages
        end
      end
    end
  end
end
