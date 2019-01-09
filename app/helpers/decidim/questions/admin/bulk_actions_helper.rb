# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      module BulkActionsHelper
        def question_find(id)
          Decidim::Questions::Question.find(id)
        end
      end
    end
  end
end
