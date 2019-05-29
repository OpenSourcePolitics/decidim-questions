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
        presenter.title
      end

      def description
        presenter.body(links: true)
      end

      def presenter
        @presenter ||= Decidim::Questions::QuestionPresenter.new(resource)
      end
    end
  end
end
