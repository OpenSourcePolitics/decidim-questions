# frozen_string_literal: true

module Decidim
  module Questions
    #
    # Decorator for questions
    #
    class QuestionPresenter < SimpleDelegator
      include Rails.application.routes.mounted_helpers
      include ActionView::Helpers::UrlHelper

      def author
        @author ||= if official?
                      Decidim::Questions::OfficialAuthorPresenter.new
                    elsif user_group
                      Decidim::UserGroupPresenter.new(user_group)
                    else
                      Decidim::UserPresenter.new(super)
                    end
      end

      def question_path
        question = __getobj__
        Decidim::ResourceLocatorPresenter.new(question).path
      end

      def display_mention
        link_to title, question_path
      end
    end
  end
end
