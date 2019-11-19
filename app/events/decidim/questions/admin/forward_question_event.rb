# frozen-string_literal: true

module Decidim
  module Questions
    module Admin
      class ForwardQuestionEvent < Decidim::Questions::Admin::QuestionEvent
        def event_has_roles?
          false
        end

        def resource_url
          question_admin_answer_url
        end
      end
    end
  end
end
