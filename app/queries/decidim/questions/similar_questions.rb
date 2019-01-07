# frozen_string_literal: true

module Decidim
  module Questions
    # Class used to retrieve similar questions.
    class SimilarQuestions < Rectify::Query
      include Decidim::TranslationsHelper

      # Syntactic sugar to initialize the class and return the queried objects.
      #
      # components - Decidim::CurrentComponent
      # question - Decidim::Questions::Question
      def self.for(components, question)
        new(components, question).query
      end

      # Initializes the class.
      #
      # components - Decidim::CurrentComponent
      # question - Decidim::Questions::Question
      def initialize(components, question)
        @components = components
        @question = question
      end

      # Retrieves similar questions
      def query
        Decidim::Questions::Question
          .where(component: @components)
          .published
          .where(
            "GREATEST(#{title_similarity}, #{body_similarity}) >= ?",
            @question.title,
            @question.body,
            Decidim::Questions.similarity_threshold
          )
          .limit(Decidim::Questions.similarity_limit)
      end

      private

      def title_similarity
        "similarity(title, ?)"
      end

      def body_similarity
        "similarity(body, ?)"
      end
    end
  end
end
