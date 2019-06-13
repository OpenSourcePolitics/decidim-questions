# frozen-string_literal: true

module Decidim
  module Questions
    module Admin
      class ForwardQuestionEvent < Decidim::Questions::Admin::QuestionEvent
        def event_has_roles?
          false
        end

        def resource_url
          EngineRouter.admin_proxy(component).edit_question_question_answer_url(question_id: resource.id, id: resource.id)
        end
      end
    end
  end
end
