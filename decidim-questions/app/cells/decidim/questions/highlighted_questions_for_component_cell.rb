# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Questions
    # This cell renders the highlighted questions for a given component.
    # It is intended to be used in the `participatory_space_highlighted_elements`
    # view hook.
    class HighlightedQuestionsForComponentCell < Decidim::ViewModel
      include Decidim::ComponentPathHelper

      def show
        render unless questions_count.zero?
      end

      private

      def questions
        @questions ||= Decidim::Questions::Question.published.not_hidden.except_withdrawn
                                                   .where(component: model)
                                                   .order_randomly(rand * 2 - 1)
      end

      def questions_to_render
        @questions_to_render ||= questions.limit(Decidim::Questions.config.participatory_space_highlighted_questions_limit)
      end

      def questions_count
        @questions_count ||= questions.count
      end
    end
  end
end
