# frozen_string_literal: true

module Decidim
  module Questions
    class NotifyQuestionsMentionedJob < ApplicationJob
      def perform(comment_id, question_metadata)
        comment = Decidim::Comments::Comment.find(comment_id)
        linked_questions = question_metadata.linked_questions
        linked_questions.each do |question_id|
          question = Question.find(question_id)
          next if question.decidim_author_id.blank?

          recipient_ids = [question.decidim_author_id]
          Decidim::EventsManager.publish(
            event: "decidim.events.questions.question_mentioned",
            event_class: Decidim::Questions::QuestionMentionedEvent,
            resource: comment.root_commentable,
            recipient_ids: recipient_ids,
            extra: {
              comment_id: comment.id,
              mentioned_question_id: question_id
            }
          )
        end
      end
    end
  end
end
