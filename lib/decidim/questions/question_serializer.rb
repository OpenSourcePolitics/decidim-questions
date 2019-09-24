# frozen_string_literal: true

module Decidim
  module Questions
    # This class serializes a Question so can be exported to CSV, JSON or other
    # formats.
    class QuestionSerializer < Decidim::Exporters::Serializer
      include Decidim::ApplicationHelper
      include Decidim::ResourceHelper
      include Decidim::TranslationsHelper

      # Public: Initializes the serializer with a question.
      def initialize(question)
        @question = question
      end

      # Public: Exports a hash with the serialized data for this question.
      def serialize
        {
            id: question.id,
            category: {
                id: question.category.try(:id),
                name: question.category.try(:name) || empty_translatable
            },
            scope: {
                id: question.scope.try(:id),
                name: question.scope.try(:name) || empty_translatable
            },
            participatory_space: {
                id: question.participatory_space.id,
                url: Decidim::ResourceLocatorPresenter.new(question.participatory_space).url
            },
            nickname: question_nickname,
            component: { id: component.id },
            title: present(question).title,
            body: present(question).body,
            state: question.state.to_s,
            reference: question.reference,
            supports: question.question_votes_count,
            endorsements: question.endorsements.count,
            comments: question.comments.count,
            attachments: question.attachments.count,
            followers: question.followers.count,
            published_at: question.published_at,
            url: url,
            meeting_urls: meetings,
            related_questions: related_questions
        }
      end

      private

      attr_reader :question

      def component
        question.component
      end

      def meetings
        question.linked_resources(:meetings, "questions_from_meeting").map do |meeting|
          Decidim::ResourceLocatorPresenter.new(meeting).url
        end
      end

      def related_questions
        question.linked_resources(:questions, "copied_from_component").map do |question|
          Decidim::ResourceLocatorPresenter.new(question).url
        end
      end

      def url
        Decidim::ResourceLocatorPresenter.new(question).url
      end

      def question_nickname
        authors = question.authors
        authors.map do |author|
          return author.nickname if author.respond_to? :nickname
          return author.name if author.respond_to? :name

          nil
        end
      end
    end
  end
end
