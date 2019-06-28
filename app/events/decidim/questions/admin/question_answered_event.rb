# frozen-string_literal: true

module Decidim
  module Questions
    module Admin
      class QuestionAnsweredEvent < Decidim::Questions::Events::WorkflowEvent
        def resource_text
          question_answer
        end

        def resource_url
          EngineRouter.admin_proxy(component).question_question_notes_url(question_id: resource.id, id: resource.id)
        end
      end
    end
  end
end
