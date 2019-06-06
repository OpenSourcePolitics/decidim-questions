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

          if user.admin? || can_manage_question?(role: :admin)
            process_admin_action?
          elsif can_manage_question?(role: :committee)
            committee_action?
          elsif can_manage_question?(role: :service)
            service_action?
          elsif can_manage_question?(role: :moderator)
            moderator_action?
          elsif can_manage_question?(role: :collaborator)
            collaborator_action?
          end

          Rails.logger.debug permission_action.inspect
          Rails.logger.debug "==========="

          permission_action
        end

        private

        def process_admin_action?
          # return unless can_manage_question?(role: :admin)

          allow! if permission_action.subject == :component && permission_action.action == :read
          allow! if permission_action.subject == :component && permission_action.action == :manage

          allow! if permission_action.subject == :question && permission_action.action == :read
          allow! if permission_action.subject == :question && permission_action.action == :edit

          allow! if permission_action.subject == :questions && permission_action.action == :read
          allow! if permission_action.subject == :questions && permission_action.action == :move
          allow! if permission_action.subject == :questions && permission_action.action == :import
          allow! if permission_action.subject == :questions && permission_action.action == :merge
          allow! if permission_action.subject == :questions && permission_action.action == :split

          allow! if permission_action.subject == :question_category && permission_action.action == :update

          allow! if permission_action.subject == :question_note && permission_action.action == :create

          if admin_creation_is_enabled?
            allow! if permission_action.subject == :question && permission_action.action == :create
          end

          if admin_question_answering_is_enabled?
            allow! if permission_action.subject == :question && permission_action.action == :answer
            allow! if permission_action.subject == :question_answer && permission_action.action == :create
          end

          if permission_action.subject == :participatory_texts && participatory_texts_are_enabled?
            allow! if permission_action.action == :manage
          end

        end

        def committee_action?
          # return unless can_manage_question?(role: :committee)

          allow! if permission_action.subject == :component && permission_action.action == :read
          allow! if permission_action.subject == :component && permission_action.action == :manage

          allow! if permission_action.subject == :question && permission_action.action == :read
          allow! if permission_action.subject == :questions && permission_action.action == :read

          allow! if permission_action.subject == :question_note && permission_action.action == :create

          if admin_question_answering_is_enabled? && is_recipient?
            allow! if permission_action.subject == :question && permission_action.action == :answer
            allow! if permission_action.subject == :question_answer && permission_action.action == :create
          end
        end

        def service_action?
          # return unless can_manage_question?(role: :service)

          allow! if permission_action.subject == :component && permission_action.action == :read
          allow! if permission_action.subject == :component && permission_action.action == :manage

          allow! if permission_action.subject == :question_note && permission_action.action == :create

          if is_recipient?

            allow! if permission_action.subject == :question && permission_action.action == :read
            allow! if permission_action.subject == :questions && permission_action.action == :read

            if admin_question_answering_is_enabled?
              allow! if permission_action.subject == :question && permission_action.action == :answer
              allow! if permission_action.subject == :question_answer && permission_action.action == :create
            end
          end
        end

        # A moderator needs to be able to read the question component they are assigned to,
        # and needs to perform all actions for the moderations of the question component.
        def moderator_action?
          # return unless can_manage_question?(role: :moderator)

          allow! if permission_action.subject == :component && permission_action.action == :read

          allow! if permission_action.subject == :question && permission_action.action == :read

          if question.try(:state).blank?
            allow! if permission_action.subject == :question && permission_action.action == :edit
          end

          allow! if permission_action.subject == :questions && permission_action.action == :read
          allow! if permission_action.subject == :questions && permission_action.action == :move

          allow! if permission_action.subject == :moderation
        end

        # Collaborators can read/preview everything inside their question component.
        def collaborator_action?
          # return unless can_manage_question?(role: :collaborator)

          allow! if permission_action.action == :read || permission_action.action == :preview
        end

        # Whether the user can manage the given process or not.
        def can_manage_question?(role: :any)
          return unless user

          participatory_processes_with_role_privileges(role).include? process
        end

        def question
          @question ||= context.fetch(:question, nil)
        end

        def admin_creation_is_enabled?
          current_settings.try(:creation_enabled?) &&
              component_settings.try(:official_questions_enabled)
        end

        def admin_question_answering_is_enabled?
          current_settings.try(:question_answering_enabled) &&
              component_settings.try(:question_answering_enabled)
        end

        def participatory_texts_are_enabled?
          component_settings.participatory_texts_enabled?
        end

        def is_recipient?
          question.try(:recipient).present? &&
            can_manage_question?(role: question.try(:recipient)) &&
            question.try(:recipient_ids).present? &&
            question.try(:recipient_ids).include?(user.id)
        end
      end
    end
  end
end
