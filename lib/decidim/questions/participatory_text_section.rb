# frozen_string_literal: true

module Decidim
  module Questions
    # The data store for a Question in the Decidim::Questions component.
    module ParticipatoryTextSection
      extend ActiveSupport::Concern

      LEVELS = {
        section: "section", sub_section: "sub-section", article: "article"
      }.freeze

      included do
        # Public: is this section an :article?
        def article?
          participatory_text_level == LEVELS[:article]
        end
      end
    end
  end
end
