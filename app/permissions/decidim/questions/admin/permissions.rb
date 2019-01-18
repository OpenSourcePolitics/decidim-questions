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
              # Every user allowed by the space can import participatory texts to questions
              allow! if permission_action.action == :import
              # Every user allowed by the space can publish participatory texts to questions
              allow! if permission_action.action == :publish
            end
          end

          committee_action?
          service_action?

          Rails.logger.debug permission_action.inspect
          Rails.logger.debug "==========="

          permission_action
        end

        private

        def committee_action?
          return unless can_manage_question?(role: :committee)
          question_actions
        end

        def service_action?
          return unless can_manage_question?(role: :service)
          question_actions
        end

        def question_actions
          # allow! if permission_action.subject == :participatory_space
          # allow! if permission_action.subject == :space_area
          # allow! if permission_action.subject == :oauth_application
          # allow! if permission_action.subject == :admin_log
          # allow! if permission_action.subject == :organization
          # allow! if permission_action.subject == :newsletter
          # allow! if permission_action.subject == :managed_user
          # allow! if permission_action.subject == :admin_user
          # allow! if permission_action.subject == :static_page
          # allow! if permission_action.subject == :moderation
          # allow! if permission_action.subject == :space_private_user
          # allow! if permission_action.subject == :process_user_role

          # allow! if permission_action.subject == :attachment
          # allow! if permission_action.subject == :attachment_collection

          # allow! if permission_action.subject == :category

          # allow! if permission_action.subject == :surveys
          # allow! if permission_action.subject == :sortitions

          # allow! if permission_action.subject == :questions

          # allow! if permission_action.subject == :proposals

          # allow! if permission_action.subject == :pages
          # allow! if permission_action.subject == :meetings
          # allow! if permission_action.subject == :debates
          # allow! if permission_action.subject == :budgets
          # allow! if permission_action.subject == :blogs
          # allow! if permission_action.subject == :accountability

          # allow! if permission_action.subject == :process
          # allow! if permission_action.subject == :component

          # allow! if permission_action.subject == :process_step

          # allow! if permission_action.subject == :question_note

          question_action
          question_note_action
          question_answer_action
        end

        def question_action
          allow! if permission_action.subject == :question && permission_action.action == :edit
          allow! if permission_action.subject == :question_category && permission_action.action == :update
        end

        def question_note_action
          # TODO: Use only read action and move component permission to the right place
          allow! if permission_action.subject == :component
          allow! if permission_action.subject == :question_note && permission_action.action == :create
        end

        def question_answer_action
          allow! if permission_action.subject == :question_answer && permission_action.action == :create
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
