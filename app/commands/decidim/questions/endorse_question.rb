# frozen_string_literal: true

module Decidim
  module Questions
    # A command with all the business logic when a user endorses a question.
    class EndorseQuestion < Rectify::Command
      # Public: Initializes the command.
      #
      # question     - A Decidim::Questions::Question object.
      # current_user - The current user.
      # current_group_id- (optional) The current_grup that is endorsing the Question.
      def initialize(question, current_user, current_group_id = nil)
        @question = question
        @current_user = current_user
        @current_group_id = current_group_id
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the question vote.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        endorsement = build_question_endorsement
        if endorsement.save
          notify_endorser_followers
          broadcast(:ok, endorsement)
        else
          broadcast(:invalid)
        end
      end

      private

      def build_question_endorsement
        endorsement = @question.endorsements.build(author: @current_user)
        endorsement.user_group = @current_user.user_groups.verified.find(@current_group_id) if @current_group_id.present?
        endorsement
      end

      def notify_endorser_followers
        recipient_ids = @current_user.followers.pluck(:id)
        Decidim::EventsManager.publish(
          event: "decidim.events.questions.question_endorsed",
          event_class: Decidim::Questions::QuestionEndorsedEvent,
          resource: @question,
          recipient_ids: recipient_ids.uniq,
          extra: {
            endorser_id: @current_user.id
          }
        )
      end
    end
  end
end
