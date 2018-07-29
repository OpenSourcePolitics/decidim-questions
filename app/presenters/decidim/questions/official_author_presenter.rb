# frozen_string_literal: true

module Decidim
  module Questions
    #
    # A dummy presenter to abstract out the author of an official question.
    #
    class OfficialAuthorPresenter
      def name
        I18n.t("decidim.questions.models.question.fields.official_question")
      end

      def nickname
        ""
      end

      def badge
        ""
      end

      def profile_path
        ""
      end

      def avatar_url
        ActionController::Base.helpers.asset_path("decidim/default-avatar.svg")
      end

      def deleted?
        false
      end
    end
  end
end
