# frozen_string_literal: true

module Decidim
  module Questions
    # Custom helpers, scoped to the questions engine.
    #
    module ControlVersionHelper
      def versions_controller?
        return true if params[:controller] == "decidim/questions/versions"

        false
      end

      def question?
        return true if item.class == Decidim::Questions::Question

        false
      end

      def back_to_resource_path_text
        return unless versions_controller?

        if question?
          t("versions.stats.back_to_question", scope: "decidim.questions")
        else
          t("versions.stats.back_to_collaborative_draft", scope: "decidim.questions")
        end
      end

      def back_to_resource_path
        return unless versions_controller?

        if question?
          question_path(item)
        else
          collaborative_draft_path(item)
        end
      end

      def resource_version_path(index)
        return unless versions_controller?

        if question?
          question_version_path(item, index + 1)
        else
          collaborative_draft_version_path(item, index + 1)
        end
      end

      def resource_all_versions_path
        return unless versions_controller?

        if question?
          question_versions_path(item)
        else
          collaborative_draft_versions_path(item)
        end
      end
    end
  end
end
