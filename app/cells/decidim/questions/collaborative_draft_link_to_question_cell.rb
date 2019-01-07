# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Questions
    # This cell renders the link to the published question of a collaborative draft.
    class CollaborativeDraftLinkToQuestionCell < Decidim::ViewModel
      def show
        render if question
      end

      private

      def question
        @question ||= model.linked_resources(:question, "created_from_collaborative_draft").first
      end

      def link_to_resource
        link_to resource_locator(question).path, class: "button secondary light expanded button--sc mt-s" do
          t("published_question", scope: "decidim.questions.collaborative_drafts.show")
        end
      end

      def link_header
        content_tag :strong, class: "text-large text-uppercase" do
          t("final_question", scope: "decidim.questions.collaborative_drafts.show")
        end
      end

      def link_help_text
        content_tag :span, class: "text-medium" do
          t("final_question_help_text", scope: "decidim.questions.collaborative_drafts.show")
        end
      end

      def link_to_versions
        @path ||= decidim_questions.collaborative_draft_versions_path(
          collaborative_draft_id: model.id
        )
        link_to @path, class: "text-medium" do
          content_tag :u do
            t("version_history", scope: "decidim.questions.collaborative_drafts.show")
          end
        end
      end

      def decidim
        Decidim::Core::Engine.routes.url_helpers
      end

      def decidim_questions
        Decidim::EngineRouter.main_proxy(model.component)
      end
    end
  end
end
