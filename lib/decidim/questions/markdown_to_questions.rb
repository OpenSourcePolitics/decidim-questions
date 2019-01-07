# frozen_string_literal: true

require "redcarpet"

module Decidim
  module Questions
    # This class parses a participatory text document in markdown and
    # produces Questions in the form of sections and articles.
    #
    # This implementation uses Redcarpet Base renderer.
    # Redcarpet::Render::Base performs a callback for every block it finds, what MarkdownToQuestions
    # does is to implement callbacks for the blocks which it is interested in performing some actions.
    #
    class MarkdownToQuestions < ::Redcarpet::Render::Base
      # Public: Initializes the serializer with a question.
      def initialize(component, current_user)
        super()
        @component = component
        @current_user = current_user
        @last_position = 0
        @num_sections = 0
      end

      def parse(document)
        renderer = self
        parser = ::Redcarpet::Markdown.new(renderer)
        parser.render(document)
      end

      ##########################################
      # Redcarpet callbacks
      ##########################################

      # Recarpet callback to process headers.
      # Creates Paricipatory Text Questions at Section and Subsection levels.
      def header(title, level)
        participatory_text_level = if level > 1
                                     Decidim::Questions::ParticipatoryTextSection::LEVELS[:sub_section]
                                   else
                                     Decidim::Questions::ParticipatoryTextSection::LEVELS[:section]
                                   end

        create_question(title, title, participatory_text_level)

        @num_sections += 1
        title
      end

      # Recarpet callback to process paragraphs.
      # Creates Paricipatory Text Questions at Article level.
      def paragraph(text)
        return if text.blank?

        create_question(
          (@last_position + 1 - @num_sections).to_s,
          text,
          Decidim::Questions::ParticipatoryTextSection::LEVELS[:article]
        )

        text
      end

      # ignore images
      def image(_link, _title, _alt_text)
        ""
      end

      private

      def create_question(title, body, participatory_text_level)
        attributes = {
          component: @component,
          title: title,
          body: body,
          participatory_text_level: participatory_text_level
        }

        question = Decidim::Questions::QuestionBuilder.create(
          attributes: attributes,
          author: @component.organization,
          action_user: @current_user
        )

        @last_position = question.position

        question
      end
    end
  end
end
