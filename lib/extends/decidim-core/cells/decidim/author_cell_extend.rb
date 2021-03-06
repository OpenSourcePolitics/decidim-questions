# frozen_string_literal: true

module Decidim
  module Questions
    module AuthorCellExtend
      def creation_date?
        return true if posts_controller?
        return unless from_context
        return unless questions_controller? || collaborative_drafts_controller?
        return unless show_action?
        true
      end
    end
  end
end

Decidim::AuthorCell.class_eval do
  prepend(Decidim::Questions::AuthorCellExtend)
end
