# frozen_string_literal: true

module Decidim
  module ContentRenderers
    # A renderer that searches Global IDs representing proposals in content
    # and replaces it with a link to their show page.
    #
    # e.g. gid://<APP_NAME>/Decidim::Questions::Question/1
    #
    # @see BaseRenderer Examples of how to use a content renderer
    class QuestionRenderer < BaseRenderer
      # Matches a global id representing a Decidim::User
      GLOBAL_ID_REGEX = %r{gid:\/\/([\w-]*\/Decidim::Questions::Question\/(\d+))}i

      # Replaces found Global IDs matching an existing proposal with
      # a link to its show page. The Global IDs representing an
      # invalid Decidim::Questions::Question are replaced with '???' string.
      #
      # @return [String] the content ready to display (contains HTML)
      def render
        content.gsub(GLOBAL_ID_REGEX) do |proposal_gid|
          begin
            question = GlobalID::Locator.locate(proposal_gid)
            Decidim::Questions::QuestionPresenter.new(question).display_mention
          rescue ActiveRecord::RecordNotFound
            question_id = question_gid.split("/").last
            "~#{question_id}"
          end
        end
      end
    end
  end
end
