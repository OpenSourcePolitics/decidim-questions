module Decidim
  module Questions
    module ParticipatoryProcesses
      module Admin
        module ParticipatoryProcessUserRolesControllerExtend
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

Decidim::ParticipatoryProcesses::Admin::ParticipatoryProcessUserRolesController.class_eval do
  prepend(Decidim::Questions::ParticipatoryProcesses::Admin::ParticipatoryProcessUserRolesControllerExtend)
end