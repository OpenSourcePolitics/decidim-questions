module Decidim
  module Questions
    module ParticipatoryProcesses
      module Admin
        module ParticipatoryProcessStepsControllerExtend
          def permission_class_chain
            [
                Decidim::Admin::RolesPermissions,
                Decidim::ParticipatoryProcesses::Permissions,
                Decidim::Admin::Permissions
            ]
          end
        end
      end
    end
  end
end

Decidim::ParticipatoryProcesses::Admin::ParticipatoryProcessStepsController.class_eval do
  prepend(Decidim::Questions::ParticipatoryProcesses::Admin::ParticipatoryProcessStepsControllerExtend)
end