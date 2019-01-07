# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Questions
    # This cell renders the list of endorsers for the given Question.
    #
    # Example:
    #
    #    cell("decidim/questions/endorsers_list", my_question)
    class EndorsersListCell < Decidim::ViewModel
      include QuestionCellsHelper

      def show
        return unless endorsers.any?
        render
      end

      private

      # Finds the correct author for each endorsement.
      #
      # Returns an Array of presented Users/UserGroups
      def endorsers
        @endorsers ||= model.endorsements.for_listing.map { |identity| present(identity.normalized_author) }
      end
    end
  end
end
