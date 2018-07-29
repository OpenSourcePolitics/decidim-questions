# frozen_string_literal: true

module Decidim
  module Questions
    # A command with all the business logic when a user updates a question.
    class UpdateQuestion < Rectify::Command
      # Public: Initializes the command.
      #
      # form         - A form object with the params.
      # current_user - The current user.
      # question - the question to update.
      def initialize(form, current_user, question)
        @form = form
        @current_user = current_user
        @question = question
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

        transaction do
          update_question
        end

        broadcast(:ok, question)
      end

      private

      attr_reader :form, :question, :current_user

      def update_question
        @question.update!(
          title: form.title,
          body: form.body,
          category: form.category,
          scope: form.scope,
          author: current_user,
          decidim_user_group_id: user_group.try(:id),
          address: form.address,
          latitude: form.latitude,
          longitude: form.longitude
        )
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
        Question.where(author: current_user, component: form.current_component).published.where.not(id: question.id)
      end

      def user_group_questions
        Question.where(user_group: user_group, component: form.current_component).published.where.not(id: question.id)
      end
    end
  end
end
