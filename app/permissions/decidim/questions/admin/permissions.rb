# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      class Permissions < Decidim::DefaultPermissions
        def permissions

          Rails.logger.debug "==========="
          Rails.logger.debug "Decidim::Questions::Admin::Permissions"
          Rails.logger.debug permission_action.inspect
          Rails.logger.debug "==========="

          # The public part needs to be implemented yet
          return permission_action if permission_action.scope != :admin

          # Administrators gets all
          # allow! if admin?

          if permission_action.action == :read
            allow! if [
              :participatory_space,
              :process,
              :component,
              # :component_data,
              :questions,
              :question,
              :question_answer
            ].include?(permission_action.subject)
          end

          # Decidim::Admin::BaseController
          allow! if permission_action.subject == :component && permission_action.action == :manage

          if permission_action.action == :create
            # There's no special condition to create question notes, only
            # users with access to the admin section can do it.
            allow! if permission_action.subject == :question_note
          end

          return permission_action unless user

          if user.admin
            org_admin_action?
          else
            case user_role
            when 'admin'
              process_admin_action?
            when 'committee'
              committee_action?
            when 'service'
              service_action?
            when 'moderator'
              moderator_action?
            when 'collaborator'
              collaborator_action?
            end
          end


          Rails.logger.debug permission_action.inspect
          Rails.logger.debug "==========="

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

        def admin?
          user.admin || user_role == 'admin'
        end

        def can_answer?
          Rails.logger.debug "==========="
          Rails.logger.debug "Decidim::Questions::Admin::Permissions.can_answer?"
          Rails.logger.debug question.inspect
          Rails.logger.debug "==========="
          return unless question
          return question.state == "evaluating" &&
            question.question_type == "question" &&
            question.recipient_role == user_role
        end

        def committee_action?
          toggle_allow(can_answer?) if permission_action.subject == :question && permission_action.action == :answer

          is_allowed = [
            [:question,:forward],
            [:question_answer,:forward],
            [:question_category,:update]
          ].include?([permission_action.subject,permission_action.action])

          allow! if is_allowed
        end

        def service_action?
          toggle_allow(can_answer?) if permission_action.subject == :question && permission_action.action == :answer
        end

        # A moderator needs to be able to read the process they are assigned to,
        # and needs to perform all actions for the moderations of that process.
        def moderator_action?
          allow! if permission_action.subject == :moderation
          toggle_allow(admin_creation_is_enabled?) if permission_action.subject == :question && permission_action.action == :create

          is_allowed = [
            [:question,:forward],
            [:question,:update],
            [:question_answer,:forward],
            [:question_category,:update],
            [:questions,:import]
          ].include?([permission_action.subject,permission_action.action])

          allow! if is_allowed
        end

        # Collaborators can read/preview everything inside their process.
        def collaborator_action?
          allow! if permission_action.action == :read || permission_action.action == :preview
        end

        # Process admins can eprform everything *inside* that process. They cannot
        # create a process or perform actions on process groups or other
        # processes. They cannot destroy their process either.
        def process_admin_action?
          return if user.admin?

          is_allowed = [
            :attachment,
            :attachment_collection,
            :category,
            :component,
            :component_data,
            :moderation,
            :process,
            :questions,
            :question,
            :question_answer,
            :question_category
          ].include?(permission_action.subject)
          allow! if is_allowed
        end

        def org_admin_action?
          return unless user.admin?
          # toggle_allow(admin_creation_is_enabled?) if permission_action.subject == :question && permission_action.action == :create

          is_allowed = [
            :attachment,
            :attachment_collection,
            :category,
            :component,
            :component_data,
            :moderation,
            :process,
            :questions,
            :question,
            :question_answer,
            :question_category
          ].include?(permission_action.subject)
          allow! if is_allowed
        end

        def process
          @process ||= context.fetch(:current_participatory_space, nil) || context.fetch(:process, nil)
        end

        def question
          @question ||= context.fetch(:question, nil) || context.fetch(:question, nil)
        end

        def user_role
          @user_role ||= user.admin ? 'admin' : ParticipatoryProcessUserRole.where(user: user, participatory_process: process).first.role
        end

      end
    end
  end
end
