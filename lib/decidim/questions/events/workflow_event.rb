# frozen_string_literal: true

module Decidim
  module Questions
    module Events
      class WorkflowEvent < Decidim::Events::SimpleEvent
        include Decidim::Questions::Events::QuestionEvent

        i18n_attributes :user_name, :user_nickname
        i18n_attributes :participatory_space_slug, :participatory_space_id

        def is_workflow?
          extra.try(:layout) == "workflow"
        end

        def user_name
          user.try(:name)
        end

        def user_nickname
          user.try(:nickname)
        end

        def participatory_space_slug
          participatory_space.try(:slug)
        end

        def participatory_space_id
          participatory_space.try(:id)
        end

        private

        def default_i18n_options
          {
            user_name: user_name,
            user_pseudo: user_nickname,
            resource_path: resource_path,
            resource_title: resource_title,
            resource_url: resource_url,
            question_title: question_title,
            question_body: question_body,
            question_answer: question_answer,
            question_reference: question_reference,
            question_short_ref: question_short_ref,
            question_url: question_url,
            question_admin_edit_url: question_admin_edit_url,
            question_admin_answer_url: question_admin_answer_url,
            question_admin_privates_notes_url: question_admin_privates_notes_url,
            participatory_space_title: participatory_space_title,
            participatory_space_url: participatory_space_url,
            participatory_space_slug: participatory_space_url,
            participatory_space_id: participatory_space_url,
            scope: i18n_scope
          }
        end
      end
    end
  end
end
