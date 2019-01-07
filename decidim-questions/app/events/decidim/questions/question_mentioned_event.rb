# frozen-string_literal: true

module Decidim
  module Questions
    class QuestionMentionedEvent < Decidim::Events::SimpleEvent
      include Decidim::ApplicationHelper

      i18n_attributes :mentioned_question_title

      private

      def mentioned_question_title
        present(mentioned_question).title
      end

      def mentioned_question
        @mentioned_question ||= Decidim::Questions::Question.find(extra[:mentioned_question_id])
      end
    end
  end
end
