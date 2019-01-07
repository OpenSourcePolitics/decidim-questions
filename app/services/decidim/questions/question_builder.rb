# frozen_string_literal: true

module Decidim
  module Questions
    # A factory class to ensure we always create Questions the same way since it involves some logic.
    module QuestionBuilder
      # Public: Creates a new Question.
      #
      # attributes        - The Hash of attributes to create the Question with.
      # author            - An Authorable the will be the first coauthor of the Question.
      # user_group_author - A User Group to, optionally, set it as the author too.
      # action_user       - The User to be used as the user who is creating the question in the traceability logs.
      #
      # Returns a Question.
      def create(attributes:, author:, action_user:, user_group_author: nil)
        Decidim.traceability.perform_action!(:create, Question, action_user, visibility: "all") do
          question = Question.new(attributes)
          question.add_coauthor(author, user_group: user_group_author)
          question.save!
          question
        end
      end

      module_function :create

      # Public: Creates a new Question by copying the attributes from another one.
      #
      # original_question - The Question to be used as base to create the new one.
      # author            - An Authorable the will be the first coauthor of the Question.
      # user_group_author - A User Group to, optionally, set it as the author too.
      # action_user       - The User to be used as the user who is creating the question in the traceability logs.
      # extra_attributes  - A Hash of attributes to create the new question, will overwrite the original ones.
      # skip_link         - Whether to skip linking the two questions or not (default false).
      #
      # Returns a Question
      #
      # rubocop:disable Metrics/ParameterLists
      def copy(original_question, author:, action_user:, user_group_author: nil, extra_attributes: {}, skip_link: false)
        origin_attributes = original_question.attributes.except(
          "id",
          "created_at",
          "updated_at",
          "state",
          "answer",
          "answered_at",
          "decidim_component_id",
          "reference",
          "question_votes_count",
          "question_endorsements_count",
          "question_notes_count"
        ).merge(
          "category" => original_question.category
        ).merge(
          extra_attributes
        )

        question = create(
          attributes: origin_attributes,
          author: author,
          user_group_author: user_group_author,
          action_user: action_user
        )

        question.link_resources(original_question, "copied_from_component") unless skip_link
        question
      end
      # rubocop:enable Metrics/ParameterLists

      module_function :copy
    end
  end
end
