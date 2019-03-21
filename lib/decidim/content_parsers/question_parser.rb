# frozen_string_literal: true

module Decidim
  module ContentParsers
    # A parser that searches mentions of Questions in content.
    #
    # This parser accepts two ways for linking Questions.
    # - Using a standard url starting with http or https.
    # - With a word starting with `~` and digits afterwards will be considered a possible mentioned question.
    # For example `~1234`, but no `~ 1234`.
    #
    # Also fills a `Metadata#linked_questions` attribute.
    #
    # @see BaseParser Examples of how to use a content parser
    class QuestionParser < BaseParser
      # Class used as a container for metadata
      #
      # @!attribute linked_questions
      #   @return [Array] an array of Decidim::Questions::Question mentioned in content
      Metadata = Struct.new(:linked_questions)

      # Matches a URL
      URL_REGEX_SCHEME = '(?:http(s)?:\/\/)'
      URL_REGEX_CONTENT = '[\w.-]+[\w\-\._~:\/?#\[\]@!\$&\'\(\)\*\+,;=.]+'
      URL_REGEX_END_CHAR = '[\d]'
      URL_REGEX = %r{#{URL_REGEX_SCHEME}#{URL_REGEX_CONTENT}/questions/#{URL_REGEX_END_CHAR}+}i
      # Matches a mentioned Question ID (~(d)+ expression)
      ID_REGEX = /~(\d+)/

      def initialize(content, context)
        super
        @metadata = Metadata.new([])
      end

      # Replaces found mentions matching an existing
      # Question with a global id for that Question. Other mentions found that doesn't
      # match an existing Question are returned as they are.
      #
      # @return [String] the content with the valid mentions replaced by a global id.
      def rewrite
        rewrited_content = parse_for_urls(content)
        parse_for_ids(rewrited_content)
      end

      # (see BaseParser#metadata)
      attr_reader :metadata

      private

      def parse_for_urls(content)
        content.gsub(URL_REGEX) do |match|
          question = question_from_url_match(match)
          if question
            @metadata.linked_questions << question.id
            question.to_global_id
          else
            match
          end
        end
      end

      def parse_for_ids(content)
        content.gsub(ID_REGEX) do |match|
          question = question_from_id_match(Regexp.last_match(1))
          if question
            @metadata.linked_questions << question.id
            question.to_global_id
          else
            match
          end
        end
      end

      def question_from_url_match(match)
        uri = URI.parse(match)
        return if uri.path.blank?

        question_id = uri.path.split("/").last
        find_question_by_id(question_id)
      rescue URI::InvalidURIError
        Rails.logger.error("#{e.message}=>#{e.backtrace}")
        nil
      end

      def question_from_id_match(match)
        question_id = match
        find_question_by_id(question_id)
      end

      def find_question_by_id(id)
        if id.present?
          spaces = Decidim.participatory_space_manifests.flat_map do |manifest|
            manifest.participatory_spaces.call(context[:current_organization]).public_spaces
          end
          components = Component.where(participatory_space: spaces).published
          Decidim::Questions::Question.where(component: components).find_by(id: id)
        end
      end
    end
  end
end
