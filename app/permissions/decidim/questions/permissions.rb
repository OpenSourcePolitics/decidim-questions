# frozen_string_literal: true

module Decidim
  module Questions
    class Permissions < Decidim::DefaultPermissions
      def permissions
        can_see_question? if permission_action.subject == :question && permission_action.action == :show
        return permission_action unless user

        # Delegate the admin permission checks to the admin permissions class
        return Decidim::Questions::Admin::Permissions.new(user, permission_action, context).permissions if permission_action.scope == :admin
        return permission_action if permission_action.scope != :public

        if permission_action.subject == :question
          apply_question_permissions(permission_action)
        elsif permission_action.subject == :collaborative_draft
          apply_collaborative_draft_permissions(permission_action)
        else
          permission_action
        end

        permission_action
      end

      private

      def apply_question_permissions(permission_action)
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
      end

      def question
        @question ||= context.fetch(:question, nil)
      end

      # It's an admin user if it's an organization admin or is a space admin
      # for the current `process`.
      def admin_user?
        user.admin? || (process ? can_manage_process?(role: :admin) : has_manageable_processes?)
      end

      # Checks if it has any manageable process, with any possible role.
      def has_manageable_processes?(role: :any)
        return unless user

        participatory_processes_with_role_privileges(role).any?
      end

      # Whether the user can manage the given process or not.
      def can_manage_process?(role: :any)
        return unless user

        participatory_processes_with_role_privileges(role).include? process
      end

      # Returns a collection of Participatory processes where the given user has the
      # specific role privilege.
      def participatory_processes_with_role_privileges(role)
        Decidim::ParticipatoryProcessesWithUserRole.for(user, role)
      end

      def public_list_processes_action?
        return unless permission_action.action == :list &&
                      permission_action.subject == :process

        allow!
      end

      def voting_enabled?
        return unless current_settings
        current_settings.votes_enabled? && !current_settings.votes_blocked?
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

      def can_see_question?
        return unless question
        if %w(accepted evaluating rejected).include?(question.state)
          allow!
        elsif user
          toggle_allow(question.authored_by?(user) || admin_user? || can_manage_process?(role: :committee) || can_manage_process?(role: :service) || can_manage_process?(role: :moderator))
        else
          disallow!
        end
      end

      def can_create_question?
        toggle_allow(authorized?(:create) && current_settings&.creation_enabled?)
      end

      def can_edit_question?
        toggle_allow(question && question.editable_by?(user))
      end

      def can_withdraw_question?
        toggle_allow(question && question.authored_by?(user))
      end

      def can_endorse_question?
        is_allowed = question &&
                     authorized?(:endorse, resource: question) &&
                     current_settings&.endorsements_enabled? &&
                     !current_settings&.endorsements_blocked?

        toggle_allow(is_allowed)
      end

      def can_unendorse_question?
        is_allowed = question &&
                     authorized?(:endorse, resource: question) &&
                     current_settings&.endorsements_enabled?

        toggle_allow(is_allowed)
      end

      def can_vote_question?
        is_allowed = question &&
                     authorized?(:vote, resource: question) &&
                     voting_enabled? &&
                     remaining_votes.positive?

        toggle_allow(is_allowed)
      end

      def can_unvote_question?
        is_allowed = question &&
                     authorized?(:vote, resource: question) &&
                     voting_enabled?

        toggle_allow(is_allowed)
      end

      def apply_collaborative_draft_permissions(permission_action)
        case permission_action.action
        when :create
          can_create_collaborative_draft?
        when :edit
          can_edit_collaborative_draft?
        when :publish
          can_publish_collaborative_draft?
        when :request_access
          can_request_access_collaborative_draft?
        end
      end

      def collaborative_draft
        @collaborative_draft ||= context.fetch(:collaborative_draft, nil)
      end

      def can_create_collaborative_draft?
        toggle_allow(authorized?(:create) && current_settings&.creation_enabled? && component_settings&.collaborative_drafts_enabled?)
      end

      def can_edit_collaborative_draft?
        toggle_allow(collaborative_draft.open? && collaborative_draft.editable_by?(user) && component_settings&.collaborative_drafts_enabled?)
      end

      def can_publish_collaborative_draft?
        toggle_allow(collaborative_draft.open? && collaborative_draft.editable_by?(user) && component_settings&.collaborative_drafts_enabled?)
      end

      def can_request_access_collaborative_draft?
        return toggle_allow(false) unless collaborative_draft.open? && component_settings&.collaborative_drafts_enabled?
        return toggle_allow(false) if collaborative_draft.editable_by?(user)
        return toggle_allow(false) if collaborative_draft.requesters.include? user
        toggle_allow(collaborative_draft && !collaborative_draft.editable_by?(user))
      end

      def process
        @process ||= context.fetch(:current_participatory_space, nil) || context.fetch(:process, nil)
      end

      def process_group
        @process_group ||= context.fetch(:process_group, nil)
      end
    end
  end
end
