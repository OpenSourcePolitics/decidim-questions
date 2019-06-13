# frozen_string_literal: true

module Decidim
  module Questions
    module ParticipatoryProcessExtend
      def has_questions_component?
        components.where(manifest_name: "questions").any?
      end

      def questions_component
        i = components.index { |i| i["manifest_name"] == "questions" }
        components[i]
      end

      def moderators_only
        "#{admin_module_name}::ModeratorsOnly".constantize.for(self)
      end

      def service_users
        "#{admin_module_name}::ServiceUsers".constantize.for(self)
      end

      def committee_users
        "#{admin_module_name}::CommitteeUsers".constantize.for(self)
      end
    end # end module ParticipatoryProcessExtends
  end # end module Questions
end # end module Decidim

Decidim::ParticipatoryProcess.class_eval do
  prepend(Decidim::Questions::ParticipatoryProcessExtend)
end
