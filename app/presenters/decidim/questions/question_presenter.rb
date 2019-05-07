# frozen_string_literal: true

module Decidim
  module Questions
    #
    # Decorator for questions
    #
    class QuestionPresenter < SimpleDelegator
      include Rails.application.routes.mounted_helpers
      include ActionView::Helpers::UrlHelper
      include Decidim::TranslationsHelper
      
      def author
        @author ||= if official?
                      Decidim::Questions::OfficialAuthorPresenter.new
                    else
                      coauthorship = coauthorships.first
                      if coauthorship.user_group
                        Decidim::UserGroupPresenter.new(coauthorship.user_group)
                      else
                        Decidim::UserPresenter.new(coauthorship.author)
                      end
                    end
      end

      def question
        __getobj__
      end

      def question_path
        Decidim::ResourceLocatorPresenter.new(question).path
      end

      def display_mention
        link_to title, question_path
      end

      # Render the question title
      #
      # links - should render hashtags as links?
      # extras - should include extra hashtags?
      #
      # Returns a String.
      def title(links: false, extras: true)
        renderer = Decidim::ContentRenderers::HashtagRenderer.new(question.title)
        renderer.render(links: links, extras: extras).html_safe
      end

      def body(links: false, extras: true)
        renderer = Decidim::ContentRenderers::HashtagRenderer.new(question.body)
        renderer.render(links: links, extras: extras).html_safe
      end

      def answer(links: false, extras: true)
        renderer = Decidim::ContentRenderers::HashtagRenderer.new(translated_attribute(question.answer))
        renderer.render(links: links, extras: extras).html_safe
      end
    end
  end
end
