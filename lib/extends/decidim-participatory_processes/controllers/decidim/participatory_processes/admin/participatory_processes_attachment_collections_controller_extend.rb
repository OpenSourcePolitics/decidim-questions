# frozen_string_literal: true

module Decidim
  module Questions
    module ParticipatoryProcesses
      module Admin
        module ParticipatoryProcessAttachmentCollectionsControllerExtend
          def permission_class_chain
            [
              Decidim::Admin::RolesPermissions,
              Decidim::ParticipatoryProcesses::Permissions,
              Decidim::Admin::Permissions
            ]
          end
        end # end module ParticipatoryProcessesControllerExtends
      end # end module Admin
    end # end module ParticipatoryProcesses
  end # end module Questions
end # end module Decidim

Decidim::ParticipatoryProcesses::Admin::ParticipatoryProcessAttachmentCollectionsController.class_eval do
  prepend(Decidim::Questions::ParticipatoryProcesses::Admin::ParticipatoryProcessAttachmentCollectionsControllerExtend)
end
