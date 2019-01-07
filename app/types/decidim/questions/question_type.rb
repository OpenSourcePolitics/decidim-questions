# frozen_string_literal: true

module Decidim
  module Questions
    QuestionType = GraphQL::ObjectType.define do
      name "Question"
      description "A question"

      interfaces [
        -> { Decidim::Comments::CommentableInterface },
        -> { Decidim::Core::AuthorableInterface },
        -> { Decidim::Core::CategorizableInterface },
        -> { Decidim::Core::ScopableInterface },
        -> { Decidim::Core::AttachableInterface }
      ]

      field :id, !types.ID
      field :title, !types.String, "This question's title"
      field :body, types.String, "This question's body"
      field :state, types.String, "The state in which question is in"
      field :address, types.String, "The physical address (location) of this question"
      field :reference, types.String, "This proposa'ls unique reference"

      field :publishedAt, Decidim::Core::DateTimeType do
        description "The date and time this question was published"
        property :published_at
      end

      field :endorsements, !types[Decidim::Core::AuthorInterface], "The endorsements of this question." do
        resolve ->(question, _, _) {
          question.endorsements.map(&:normalized_author)
        }
      end

      field :endorsementsCount, types.Int do
        description "The total amount of endorsements the question has received"
        property :question_endorsements_count
      end

      field :voteCount, types.Int do
        description "The total amount of votes the question has received"
        resolve ->(question, _args, _ctx) {
          current_component = question.component
          question.question_votes_count unless current_component.current_settings.votes_hidden?
        }
      end
    end
  end
end
