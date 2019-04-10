# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      class Permissions < Decidim::ParticipatoryProcesses::Permissions
        def permissions
          Rails.logger.debug "==========="
          Rails.logger.debug "Decidim::Questions::Admin::Permissions"
          Rails.logger.debug permission_action.inspect
          Rails.logger.debug "==========="

          # The public part needs to be implemented yet
          return permission_action if permission_action.scope != :admin

          has_access? if permission_action.subject == :component && permission_action.action == :read
          has_access? if permission_action.subject == :question && permission_action.action == :read

          if create_permission_action?
            # There's no special condition to create question notes, only
            # users with access to the admin section can do it.
            allow! if permission_action.subject == :question_note
            # Questions can only be created from the admin when the
            # corresponding setting is enabled.
            toggle_allow(admin_creation_is_enabled?) if permission_action.subject == :question #
            # Questions can only be answered from the admin when the
            # corresponding setting is enabled.
            toggle_allow(admin_question_answering_is_enabled?) if permission_action.subject == :question_answer
          end

          if user.admin?
            # Admins can only edit official questions if they are within the
            # time limit.
            allow! if permission_action.subject == :question && permission_action.action == :edit
            # Every user allowed by the space can update the category of the question
            allow! if permission_action.subject == :question_category && permission_action.action == :update
            # Every user allowed by the space can import questions from another_component
            allow! if permission_action.subject == :questions && permission_action.action == :import
            # Every user allowed by the space can merge questions to another component
            allow! if permission_action.subject == :questions && permission_action.action == :merge
            # Every user allowed by the space can split questions to another component
            allow! if permission_action.subject == :questions && permission_action.action == :split
            if permission_action.subject == :participatory_texts && participatory_texts_are_enabled?
              # Every user allowed by the space can manage (import, update and publish) participatory texts to questions
              allow! if permission_action.action == :manage
            end
          end

          committee_action?
          service_action?

          moderator_action?
          collaborator_action?
          process_admin_action?

          Rails.logger.debug permission_action.inspect
          Rails.logger.debug "==========="

          permission_action
        end

        private

        def process_admin_action?
          return unless can_manage_question?(role: :admin)

          allow! if permission_action.subject == :component && permission_action.action == :read
          allow! if permission_action.subject == :question && permission_action.action == :edit
          question_actions
        end

        # A moderator needs to be able to read the question component they are assigned to,
        # and needs to perform all actions for the moderations of the question component.
        def moderator_action?
          return unless can_manage_question?(role: :moderator)

          allow! if permission_action.subject == :moderation
        end

        # Collaborators can read/preview everything inside their question component.
        def collaborator_action?
          return unless can_manage_question?(role: :collaborator)

          allow! if permission_action.action == :read || permission_action.action == :preview
        end

        def process_admin?
          can_manage_question?(role: :admin)
        end

        def committee_action?
          return unless can_manage_question?(role: :committee)
          allow! if permission_action.subject == :moderation
          allow! if permission_action.subject == :question && permission_action.action == :edit
          question_actions
        end

        def service_action?
          return unless can_manage_question?(role: :service)

          question_actions
        end

        def question_actions
          allow! if permission_action.subject == :questions && permission_action.action == :read
          question_note_action
          question_answer_action
        end

        def question_note_action
          # TODO: Use only read action and move component permission to the right place
          allow! if permission_action.subject == :component && permission_action.action == :manage

          allow! if permission_action.subject == :question_note && permission_action.action == :create
        end

        def question_answer_action
          allow! if admin_question_answering_is_enabled? && permission_action.subject == :question_answer && permission_action.action == :create
        end

        # Whether the user can manage the given process or not.
        def can_manage_question?(role: :any)
          return unless user

          participatory_processes_with_role_privileges(role).include? process
        end

        def question
          @question ||= context.fetch(:question, nil)
        end

        def has_access?
          toggle_allow(admin_user? ||
                           can_manage_process?(role: :committee) ||
                           can_manage_process?(role: :service))
        end

        def admin_creation_is_enabled?
          current_settings.try(:creation_enabled?) &&
              component_settings.try(:official_questions_enabled)
        end

        def admin_question_answering_is_enabled?
          current_settings.try(:question_answering_enabled) &&
              component_settings.try(:question_answering_enabled)
        end

        def create_permission_action?
          permission_action.action == :create
        end

        def participatory_texts_are_enabled?
          component_settings.participatory_texts_enabled?
        end
      end
    end
  end
end
