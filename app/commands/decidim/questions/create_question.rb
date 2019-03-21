# frozen_string_literal: true

module Decidim
  module Questions
    # A command with all the business logic when a user creates a new question.
    class CreateQuestion < Rectify::Command
      include AttachmentMethods
      include HashtagsMethods

      # Public: Initializes the command.
      #
      # form         - A form object with the params.
      # current_user - The current user.
      # coauthorships - The coauthorships of the question.
      def initialize(form, current_user, coauthorships = nil)
        @form = form
        @current_user = current_user
        @coauthorships = coauthorships
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid, together with the question.
      # - :invalid if the form wasn't valid and we couldn't proceed.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) if form.invalid?

        if question_limit_reached?
          form.errors.add(:base, I18n.t("decidim.questions.new.limit_reached"))
          return broadcast(:invalid)
        end

        transaction do
          create_question
        end

        broadcast(:ok, question)
      end

      private

      attr_reader :form, :question, :attachment

      # Prevent PaperTrail from creating an additional version
      # in the question multi-step creation process (step 1: create)
      #
      # A first version will be created in step 4: publish
      # for diff rendering in the question version control
      def create_question
        PaperTrail.request(enabled: false) do
          @question = Decidim.traceability.perform_action!(
            :create,
            Decidim::Questions::Question,
            @current_user,
            visibility: "public-only"
          ) do
            question = Question.new(
              title: title_with_hashtags,
              body: body_with_hashtags,
              component: form.component
            )
            question.add_coauthor(@current_user, user_group: user_group)
            question.save!
            question
          end
        end
      end

      def question_limit_reached?
        return false if @coauthorships.present?

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
        @organization ||= @current_user.organization
      end

      def current_user_questions
        Question.from_author(@current_user).where(component: form.current_component).except_withdrawn
      end

      def user_group_questions
        Question.from_user_group(@user_group).where(component: form.current_component).except_withdrawn
      end
    end
  end
end
