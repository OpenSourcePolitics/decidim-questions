# frozen_string_literal: true

module Decidim
  module Questions
    # A command with all the business logic when a user publishes a collaborative_draft.
    class PublishCollaborativeDraft < Rectify::Command
      # Public: Initializes the command.
      #
      # collaborative_draft - The collaborative_draft to publish.
      # current_user - The current user.
      # question_form - the form object of the new question
      def initialize(collaborative_draft, current_user)
        @collaborative_draft = collaborative_draft
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid and the collaborative_draft is published.
      # - :invalid if the collaborative_draft's author is not the current user.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) unless @collaborative_draft.open?
        return broadcast(:invalid) unless @collaborative_draft.authored_by? @current_user

        transaction do
          reject_access_to_collaborative_draft
          publish_collaborative_draft
          create_question!
          link_collaborative_draft_and_question
        end

        broadcast(:ok, @new_question)
      end

      attr_accessor :new_question

      private

      def reject_access_to_collaborative_draft
        @collaborative_draft.requesters.each do |requester_user|
          RejectAccessToCollaborativeDraft.call(@collaborative_draft, current_user, requester_user)
        end
      end

      def publish_collaborative_draft
        Decidim.traceability.update!(
          @collaborative_draft,
          @current_user,
          { state: "published", published_at: Time.current },
          visibility: "public-only"
        )
      end

      def question_attributes
        fields = {}

        parsed_title = Decidim::ContentProcessor.parse_with_processor(:hashtag, @collaborative_draft.title, current_organization: @collaborative_draft.organization).rewrite
        parsed_body = Decidim::ContentProcessor.parse_with_processor(:hashtag, @collaborative_draft.body, current_organization: @collaborative_draft.organization).rewrite

        fields[:title] = parsed_title
        fields[:body] = parsed_body
        fields[:component] = @collaborative_draft.component
        fields[:scope] = @collaborative_draft.scope
        fields[:address] = @collaborative_draft.address
        fields[:published_at] = Time.current

        fields
      end

      def create_question!
        @new_question = Decidim.traceability.perform_action!(
          :create,
          Decidim::Questions::Question,
          @current_user,
          visibility: "public-only"
        ) do
          new_question = Question.new(question_attributes)
          new_question.coauthorships = @collaborative_draft.coauthorships
          new_question.category = @collaborative_draft.category
          new_question.attachments = @collaborative_draft.attachments
          new_question.save!
          new_question
        end
      end

      def link_collaborative_draft_and_question
        @collaborative_draft.link_resources(@new_question, "created_from_collaborative_draft")
      end
    end
  end
end
