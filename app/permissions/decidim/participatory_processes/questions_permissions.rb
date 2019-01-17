# frozen_string_literal: true

module Decidim
  module ParticipatoryProcesses
    class QuestionsPermissions < Decidim::ParticipatoryProcesses::Permissions
      def permissions

        Rails.logger.debug "==========="
        Rails.logger.debug "Decidim::ParticipatoryProcesses::QuestionsPermissions"
        Rails.logger.debug permission_action.inspect
        Rails.logger.debug "==========="

        committee_action?
        service_action?

        org_admin_action?

        Rails.logger.debug permission_action.inspect
        Rails.logger.debug "==========="

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

      def questions_action?
        return if permission_action.subject == :process &&
                    [:create,:update].include?(permission_action.action)

        is_allowed = [
          :component,
          :component_data,
          :questions,
          :question,
          :participatory_space,
          :process
        ].include?(permission_action.subject)
        allow! if is_allowed
      end

    end
  end
end
