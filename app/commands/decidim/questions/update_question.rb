# frozen_string_literal: true

module Decidim
  module Questions
    # A command with all the business logic when a user updates a question.
    class UpdateQuestion < Rectify::Command
      include AttachmentMethods
      include HashtagsMethods

      # Public: Initializes the command.
      #
      # form         - A form object with the params.
      # current_user - The current user.
      # question - the question to update.
      def initialize(form, current_user, question)
        @form = form
        @current_user = current_user
        @question = question
        @attached_to = question
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the question.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if form.invalid?
        return broadcast(:invalid) unless question.editable_by?(current_user)
        return broadcast(:invalid) if question_limit_reached?

        if process_attachments?
          @question.attachments.destroy_all

          build_attachment
          return broadcast(:invalid) if attachment_invalid?
        end

        transaction do
          if @question.draft?
            update_draft
          else
            update_question
          end
          create_attachment if process_attachments?
        end

        broadcast(:ok, question)
      end

      private

      attr_reader :form, :question, :current_user, :attachment

      def question_attributes
        fields = {}

        fields[:title] = title_with_hashtags
        fields[:body] = body_with_hashtags
        fields[:category] = form.category
        fields[:scope] = form.scope
        fields[:address] = form.address
        fields[:latitude] = form.latitude
        fields[:longitude] = form.longitude

        fields
      end

      # Prevent PaperTrail from creating an additional version
      # in the question multi-step creation process (step 3: complete)
      def update_draft
        PaperTrail.request(enabled: false) do
          @question.update(question_attributes)
          @question.coauthorships.clear
          @question.add_coauthor(current_user, user_group: user_group)
        end
      end

      def update_question
        @question = Decidim.traceability.update!(
          @question,
          current_user,
          question_attributes,
          visibility: "public-only"
        )
        @question.coauthorships.clear
        @question.add_coauthor(current_user, user_group: user_group)
      end

      def question_limit_reached?
        question_limit = form.current_component.settings.question_limit

        return false if question_limit.zero?

        if user_group
          user_group_questions.count >= question_limit
        else
          current_user_questions.count >= question_limit
        end
      end

      def user_group
        @user_group ||= Decidim::UserGroup.find_by(organization: organization, id: form.user_group_id)
      end

      def organization
        @organization ||= current_user.organization
      end

      def current_user_questions
        Question.from_author(current_user).where(component: form.current_component).published.where.not(id: question.id)
      end

      def user_group_questions
        Question.from_user_group(user_group).where(component: form.current_component).published.where.not(id: question.id)
      end
    end
  end
end
