# frozen_string_literal: true

module Decidim
  module Questions
    module AdminLog
      module ValueTypes
        class QuestionStatePresenter < Decidim::Log::ValueTypes::DefaultPresenter
          def present
            return unless value
            h.t(value, scope: "decidim.questions.admin.question_answers.edit", default: value)
          end
        end
      end
    end
  end
end
