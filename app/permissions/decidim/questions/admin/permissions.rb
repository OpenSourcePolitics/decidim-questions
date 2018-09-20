# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      class Permissions < Decidim::DefaultPermissions
        def permissions
          # The public part needs to be implemented yet
          return permission_action if permission_action.scope != :admin

          # Administrators gets all
          # allow! if admin?

          # if create_permission_action?
          #   # There's no special condition to create question notes, only
          #   # users with access to the admin section can do it.
          #   allow! if permission_action.subject == :question_note
          #
          #   # Questions can only be created from the admin when the
          #   # corresponding setting is enabled.
          #   toggle_allow(admin_creation_is_enabled?) if permission_action.subject == :question
          #
          #   # Questions can only be answered from the admin when the
          #   # corresponding setting is enabled.
          #   toggle_allow(admin_question_answering_is_enabled?) if permission_action.subject == :question_answer
          # end
          #
          # # Every user allowed by the space can update the category of the question
          # allow! if permission_action.subject == :question_category && permission_action.action == :update
          #
          # # Every user allowed by the space can import questions from another_component
          # allow! if permission_action.subject == :questions && permission_action.action == :import
          #
          # allow! if permission_action.action == :answer && ['service','committee'].include?(user_role)

          is_allowed = [
            :component,
            # :component_data,
            :questions,
            :question
          ].include?(permission_action.subject)
          allow! if is_allowed
          permission_action
        end

        private

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

        def admin?
          user.admin || user_role == 'admin'
        end

        def process
          @process ||= context.fetch(:current_participatory_space, nil) || context.fetch(:process, nil)
        end

        def user_role
          @user_role ||= user.admin ? 'admin' : ParticipatoryProcessUserRole.where(user: user, participatory_process: process).first.role
        end

      end
    end
  end
end
