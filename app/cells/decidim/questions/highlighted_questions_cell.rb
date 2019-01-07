# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Questions
    # This cell renders the highlighted questions for a given participatory
    # space. It is intended to be used in the `participatory_space_highlighted_elements`
    # view hook.
    class HighlightedQuestionsCell < Decidim::ViewModel
      include QuestionCellsHelper

      private

      def published_components
        Decidim::Component
          .where(
            participatory_space: model,
            manifest_name: :questions
          )
          .published
      end
    end
  end
end
