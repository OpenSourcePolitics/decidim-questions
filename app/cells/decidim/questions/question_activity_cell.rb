# frozen_string_literal: true

module Decidim
  module Questions
    # A cell to display when a question has been published.
    class QuestionActivityCell < ActivityCell
      def title
        I18n.t(
          "decidim.questions.last_activity.new_question_at_html",
          link: participatory_space_link
        )
      end

      def resource_link_text
        Decidim::Questions::QuestionPresenter.new(resource).title
      end
    end
  end
end
