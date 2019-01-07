# frozen_string_literal: true

module Decidim
  module Questions
    # Contains the meta data of the document, like title and description.
    #
    class ParticipatoryText < Questions::ApplicationRecord
      include Decidim::HasComponent
      include Decidim::Traceable
      include Decidim::Loggable
    end
  end
end
