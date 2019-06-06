# frozen_string_literal: true

module Decidim
  module Questions
    module Events
      module QuestionEvent
        extend ActiveSupport::Concern

        included do
          i18n_attributes :question_title, :question_body, :question_answer
          i18n_attributes :question_reference, :question_short_ref
          i18n_attributes :question_url, :question_admin_edit_url
          i18n_attributes :question_admin_answer_url, :question_admin_privates_notes_url

          def question_presenter
            return unless resource

            @question_presenter ||= Decidim::Questions::QuestionPresenter.new(resource)
          end

          def resource_text
            question_presenter.try(:body)
          end

          def question_reference
            resource.reference
          end

          def question_short_ref
            resource.short_ref
          end

          def question_answer
            question_presenter.try(:answer)
          end

          def question_body
            resource_text
          end

          def question_title
            resource_title
          end

          def question_url
            resource_url
          end

          def question_admin_edit_url
            EngineRouter.admin_proxy(component).edit_question_url(question_id: resource.id, id: resource.id)
          end

          def question_admin_answer_url
            EngineRouter.admin_proxy(component).edit_question_question_answer_url(question_id: resource.id, id: resource.id)
          end

          def question_admin_privates_notes_url
            EngineRouter.admin_proxy(component).question_question_notes_url(question_id: resource.id, id: resource.id)
          end
        end
      end
    end
  end
end
