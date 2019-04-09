# frozen_string_literal: true

module Decidim
  module ParticipatoryProcesses
    class QuestionsPermissions < Decidim::ParticipatoryProcesses::Permissions
      def permissions

        committee_action?
        service_action?
        org_admin_action?

        permission_action
      end

      def committee_action?
        return unless can_manage_process?(role: :committee)
        questions_action?
      end

      def service_action?
        return unless can_manage_process?(role: :service)
        questions_action?
      end

      private

      # TODO: REVIEW PERMISSIONS
      def questions_action?
        return if permission_action.subject == :process &&
                  %i[create update].include?(permission_action.action)

        is_allowed = %i[
          participatory_space
          component
          component_data
          questions
          question
          participatory_space
          process
        ].include?(permission_action.subject)
        allow! if is_allowed
      end
    end
  end
end
