# frozen_string_literal: true

module Decidim
  module Questions
    # A Helper to find and render the author of a version.
    module TraceabilityHelper
      include Decidim::TraceabilityHelper

      # Caches a DiffRenderer instance for the `current_version`.
      def diff_renderer
        @diff_renderer = Decidim::Questions::DiffRenderer.new(current_version)
      end
    end
  end
end
