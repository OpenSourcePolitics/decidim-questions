# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      #  A command with all the business logic when an admin batch updates questions category.
      class UpdateQuestionCategory < Rectify::Command
        # Public: Initializes the command.
        #
        # category_id - the category id to update
        # question_ids - the questions ids to update.
        def initialize(category_id, question_ids)
          @category = Decidim::Category.find_by id: category_id
          @question_ids = question_ids
          @response = { category_name: "", successful: [], errored: [] }
        end

        # Executes the command. Broadcasts these events:
        #
        # - :update_questions_category - when everything is ok, returns @response.
        # - :invalid_category - if the category is blank.
        # - :invalid_question_ids - if the question_ids is blank.
        #
        # Returns @response hash:
        #
        # - :category_name - the translated_name of the category assigned
        # - :successful - Array of names of the updated questions
        # - :errored - Array of names of the questions not updated because they already had the category assigned
        def call
          return broadcast(:invalid_category) if @category.blank?
          return broadcast(:invalid_question_ids) if @question_ids.blank?

          @response[:category_name] = @category.translated_name
          Question.where(id: @question_ids).find_each do |question|
            if @category == question.category
              @response[:errored] << question.title
            else
              transaction do
                update_question_category question
                notify_author question if question.coauthorships.any?
              end
              @response[:successful] << question.title
            end
          end

          broadcast(:update_questions_category, @response)
        end

        private

        def update_question_category(question)
          question.update!(
            category: @category
          )
        end

        def notify_author(question)
          Decidim::EventsManager.publish(
            event: "decidim.events.questions.question_update_category",
            event_class: Decidim::Questions::Admin::UpdateQuestionCategoryEvent,
            resource: question,
            affected_users: question.notifiable_identities
          )
        end
      end
    end
  end
end
