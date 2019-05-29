# frozen_string_literal: true

module Decidim
  module ParticipatoryProcesses
    module Admin
      # A class used to find the users that can operate as service members
      class ServiceUsers < Rectify::Query
        # Syntactic sugar to initialize the class and return the queried objects.
        #
        # process - a process that needs to find its moderators
        def self.for(process)
          new(process).query
        end

        # Initializes the class.
        #
        # process - a process that needs to find its process admins
        def initialize(process)
          @process = process
        end

        # Finds the users with role service for the given
        # process.
        #
        # Returns an ActiveRecord::Relation.
        def query
          Decidim::User.where(id: organization_admins + process_users)
        end

        private

        attr_reader :process

        def organization_admins
          process.organization.admins
        end

        def process_users
          Decidim::ParticipatoryProcessUserRole
            .where(participatory_process: process)
            .where(role: [:admin, :service])
            .pluck(:decidim_user_id)
            .uniq
        end
      end
    end
  end
end
