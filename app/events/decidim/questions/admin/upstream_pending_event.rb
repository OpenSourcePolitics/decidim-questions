# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      class UpstreamPendingEvent < Decidim::Questions::Admin::QuestionEvent

        def event_has_roles?
          true
        end
      
      end
    end
  end
end
