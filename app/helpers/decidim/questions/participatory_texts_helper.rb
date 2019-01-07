# frozen_string_literal: true

module Decidim
  module Questions
    # Simple helper to handle markup variations for participatory texts related partials
    module ParticipatoryTextsHelper
      # Returns the title for a given participatory text section.
      #
      # question - The current question item.
      #
      # Returns a string with the title of the section, subsection or article.
      def preview_participatory_text_section_title(question)
        translated = t(question.participatory_text_level, scope: "decidim.questions.admin.participatory_texts.sections", title: question.title)
        translated.html_safe
      end

      def render_participatory_text_title(participatory_text)
        if participatory_text.nil?
          t("alternative_title", scope: "decidim.questions.participatory_text_question")
        else
          translated_attribute(participatory_text.title)
        end
      end
    end
  end
end
