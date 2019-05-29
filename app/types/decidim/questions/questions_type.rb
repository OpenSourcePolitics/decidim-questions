# frozen_string_literal: true

module Decidim
  module Questions
    QuestionsType = GraphQL::ObjectType.define do
      interfaces [-> { Decidim::Core::ComponentInterface }]

      name "Questions"
      description "A questions component of a participatory space."

      connection :questions, QuestionType.connection_type do
        resolve ->(component, _args, _ctx) {
                  QuestionsTypeHelper.base_scope(component).includes(:component)
                }
      end

      field(:question, QuestionType) do
        argument :id, !types.ID

        resolve ->(component, args, _ctx) {
          QuestionsTypeHelper.base_scope(component).find_by(id: args[:id])
        }
      end
    end

    module QuestionsTypeHelper
      def self.base_scope(component)
        Question
          .where(component: component)
          .published
          .state_visible
          .not_hidden
          .upstream_not_hidden
      end
    end
  end
end
