# frozen_string_literal: true

module Decidim
  module Questions
    module ParticipatoryProcesses
      module ParticipatoryProcessesControllerExtends

        def permission_class_chain
          [
            Decidim::ParticipatoryProcesses::QuestionsPermissions,
            Decidim::ParticipatoryProcesses::Permissions,
            Decidim::Admin::Permissions
          ]
        end
      end # end module ParticipatoryProcessesControllerExtends
    end # end module ParticipatoryProcesses
  end # end module Questions
end # end module Decidim

Decidim::ParticipatoryProcesses::Admin::ParticipatoryProcessesController.class_eval do
  prepend(Decidim::Questions::ParticipatoryProcesses::ParticipatoryProcessesControllerExtends)
end
