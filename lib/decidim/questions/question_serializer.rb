# frozen_string_literal: true

module Decidim
  module Questions
    # This class serializes a Question so can be exported to CSV, JSON or other
    # formats.
    class QuestionSerializer < Decidim::Exporters::Serializer
      include Decidim::ResourceHelper

      # Public: Initializes the serializer with a question.
      def initialize(question)
        @question = question
      end

      # Public: Exports a hash with the serialized data for this question.
      def serialize
        {
          id: @question.id,
          category: {
            id: @question.category.try(:id),
            name: @question.category.try(:name)
          },
          scope: {
            id: @question.scope.try(:id),
            name: @question.scope.try(:name)
          },
          title: @question.title,
          body: @question.body,
          state: @question.state,
          type: @question.question_type,
          answer: @question.answer,
          recipient: @question.recipient_role,
          votes: @question.question_votes_count,
          comments: @question.comments.count,
          created_at: @question.created_at,
          url: url,
          component: { id: component.id },
          meeting_urls: meetings
        }
      end

      private

      attr_reader :question

      def component
        question.component
      end

      def meetings
        @question.linked_resources(:meetings, "questions_from_meeting").map do |meeting|
          Decidim::ResourceLocatorPresenter.new(meeting).url
        end
      end

      def url
        Decidim::ResourceLocatorPresenter.new(question).url
      end
    end
  end
end
