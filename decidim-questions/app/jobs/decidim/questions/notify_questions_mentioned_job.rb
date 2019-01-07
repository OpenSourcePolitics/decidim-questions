# frozen_string_literal: true

module Decidim
  module Questions
    class NotifyQuestionsMentionedJob < ApplicationJob
      def perform(comment_id, linked_questions)
        comment = Decidim::Comments::Comment.find(comment_id)

        linked_questions.each do |question_id|
          question = Question.find(question_id)
          affected_users = question.notifiable_identities

          Decidim::EventsManager.publish(
            event: "decidim.events.questions.question_mentioned",
            event_class: Decidim::Questions::QuestionMentionedEvent,
            resource: comment.root_commentable,
            affected_users: affected_users,
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
