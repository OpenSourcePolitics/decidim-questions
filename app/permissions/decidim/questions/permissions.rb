# frozen_string_literal: true

module Decidim
  module Questions
    class Permissions < Decidim::DefaultPermissions
      def permissions
        return permission_action unless user

        # Delegate the admin permission checks to the admin permissions class
        return Decidim::Questions::Admin::Permissions.new(user, permission_action, context).permissions if permission_action.scope == :admin
        return permission_action if permission_action.scope != :public

        return permission_action if permission_action.subject != :question

        case permission_action.action
        when :create
          can_create_question?
        when :edit
          can_edit_question?
        when :withdraw
          can_withdraw_question?
        when :endorse
          can_endorse_question?
        when :unendorse
          can_unendorse_question?
        when :vote
          can_vote_question?
        when :unvote
          can_unvote_question?
        when :report
          true
        end

        permission_action
      end

      private

      def question
        @question ||= context.fetch(:question, nil)
      end

      def voting_enabled?
        return unless current_settings
        (current_settings.votes_enabled? || current_settings.votes_weight_enabled?) && !current_settings.votes_blocked?
      end

      def vote_limit_enabled?
        return unless component_settings
        component_settings.vote_limit.present? && component_settings.vote_limit.positive?
      end

      def remaining_votes
        return 1 unless vote_limit_enabled?

        questions = Question.where(component: component)
        votes_count = QuestionVote.where(author: user, question: questions).size
        component_settings.vote_limit - votes_count
      end

      def can_create_question?
        toggle_allow(authorized?(:create) && current_settings&.creation_enabled?)
      end

      def can_edit_question?
        toggle_allow(question && question.editable_by?(user))
      end

      def can_withdraw_question?
        toggle_allow(question && question.author == user)
      end

      def can_endorse_question?
        is_allowed = question &&
                     authorized?(:endorse) &&
                     current_settings&.endorsements_enabled? &&
                     !current_settings&.endorsements_blocked?

        toggle_allow(is_allowed)
      end

      def can_unendorse_question?
        is_allowed = question &&
                     authorized?(:endorse) &&
                     current_settings&.endorsements_enabled?

        toggle_allow(is_allowed)
      end

      def can_vote_question?
        is_allowed = question &&
                     authorized?(:vote) &&
                     voting_enabled? &&
                     remaining_votes.positive?

        toggle_allow(is_allowed)
      end

      def can_unvote_question?
        is_allowed = question &&
                     authorized?(:vote) &&
                     voting_enabled?

        toggle_allow(is_allowed)
      end
    end
  end
end
