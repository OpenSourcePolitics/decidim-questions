# frozen_string_literal: true

require "decidim/questions/admin"
require "decidim/questions/engine"
require "decidim/questions/admin_engine"
require "decidim/questions/component"
require "acts_as_list"

module Decidim
  # This namespace holds the logic of the `Questions` component. This component
  # allows users to create questions in a participatory process.
  module Questions
    autoload :QuestionSerializer, "decidim/questions/question_serializer"
    autoload :CommentableQuestion, "decidim/questions/commentable_question"
    autoload :CommentableCollaborativeDraft, "decidim/questions/commentable_collaborative_draft"
    autoload :MarkdownToQuestions, "decidim/questions/markdown_to_questions"
    autoload :ParticipatoryTextSection, "decidim/questions/participatory_text_section"
    autoload :DocToMarkdown, "decidim/questions/doc_to_markdown"
    autoload :OdtToMarkdown, "decidim/questions/odt_to_markdown"
    autoload :Events, "decidim/questions/events"

    include ActiveSupport::Configurable

    # Public Setting that defines the similarity minimum value to consider two
    # questions similar. Defaults to 0.25.
    config_accessor :similarity_threshold do
      0.25
    end

    # Public Setting that defines how many similar questions will be shown.
    # Defaults to 10.
    config_accessor :similarity_limit do
      10
    end

    # Public Setting that defines how many questions will be shown in the
    # participatory_space_highlighted_elements view hook
    config_accessor :participatory_space_highlighted_questions_limit do
      4
    end

    # Public Setting that defines how many questions will be shown in the
    # process_group_highlighted_elements view hook
    config_accessor :process_group_highlighted_questions_limit do
      3
    end
  end

  module ContentParsers
    autoload :QuestionParser, "decidim/content_parsers/question_parser"
  end

  module ContentRenderers
    autoload :QuestionRenderer, "decidim/content_renderers/question_renderer"
  end
end
