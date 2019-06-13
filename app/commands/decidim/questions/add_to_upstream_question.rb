# frozen_string_literal: true

module Decidim
  module Questions
    class AddToUpstreamQuestion < Rectify::Command
      # Public: Initializes the command.
      #
      # question     - The question to publish.
      # current_user - The current user.
      def initialize(question, current_user)
        @question = question
        @current_user = current_user
      end

      # Executes the command. Broadcasts these events:
      #
      # - :ok when everything is valid and the question is published.
      # - :invalid if the question's author is not the current user.
      #
      # Returns nothing.
      def call
        return broadcast(:invalid) unless @question.authored_by?(@current_user)

        transaction do
          add_to_upstream_moderation
          @question.update(
            title: reset(:title),
            body: reset(:body),
            published_at: Time.current
          )
        end

        broadcast(:ok, @question)
      end

      def add_to_upstream_moderation
        Decidim::UpstreamModeration.find_or_create_by!(
          upstream_reportable: @question,
          participatory_space: participatory_space
        ).update!(hidden_at: Time.zone.now)

        send_upstream_notifications
      end

      private

      # Reset the attribute to an empty string and return the old value
      def reset(attribute)
        attribute_value = @question[attribute]
        PaperTrail.request(enabled: false) do
          # rubocop:disable Rails/SkipsModelValidations
          @question.update_attribute attribute, ""
          # rubocop:enable Rails/SkipsModelValidations
        end
        attribute_value
      end

      def send_upstream_notifications
        Decidim::EventsManager.publish(
          event: "decidim.events.questions.admin.upstream_pending",
          event_class: Decidim::Questions::Admin::UpstreamPendingEvent,
          resource: @question,
          affected_users: @question.authors,
          followers: participatory_space_admins
        )
      end

      def participatory_space_admins
        @participatory_space_admins ||= participatory_space.admins
      end

      def participatory_space_moderators
        @participatory_space_moderators ||= participatory_space.moderators
      end

      def participatory_space
        @participatory_space ||= @question.try(:component).try(:participatory_space)
      end
    end
  end
end
