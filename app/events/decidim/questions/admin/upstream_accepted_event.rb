# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      class UpstreamAcceptedEvent < Decidim::Questions::Admin::QuestionEvent
        def event_has_roles?
          false
        end
      end
    end
  end
end
