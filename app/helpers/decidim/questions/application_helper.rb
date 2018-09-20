# frozen_string_literal: true

module Decidim
  module Questions
    # Custom helpers, scoped to the questions engine.
    #
    module ApplicationHelper
      include Decidim::Comments::CommentsHelper
      include PaginateHelper
      include QuestionVotesHelper
      include QuestionEndorsementsHelper
      include Decidim::MapHelper
      include Decidim::Questions::MapHelper

      # Public: The state of a question in a way a human can understand.
      #
      # state - The String state of the question.
      #
      # Returns a String.
      def humanize_question_state(state)
        I18n.t(state, scope: "decidim.questions.answers", default: :not_answered)
      end

      # Public: The css class applied based on the question state.
      #
      # state - The String state of the question.
      #
      # Returns a String.
      def question_state_css_class(state)
        case state
        when "accepted"
          "text-success"
        when "rejected"
          "text-alert"
        when "evaluating"
          "text-info"
        else
          "text-warning"
        end
      end

      # Public: The css class applied based on the question state to
      #         the question badge.
      #
      # state - The String state of the question.
      #
      # Returns a String.
      def question_state_badge_css_class(state)
        case state
        when "accepted"
          "success"
        when "rejected"
          "warning"
        when "evaluating"
          "secondary"
        when "withdrawn"
          "alert"
        end
      end

      def question_limit_enabled?
        question_limit.present?
      end

      def question_limit
        return if component_settings.question_limit.zero?

        component_settings.question_limit
      end

      def current_user_questions
        Question.where(component: current_component, author: current_user)
      end

      def follow_button_for(model)
        if current_user
          render partial: "decidim/shared/follow_button.html", locals: { followable: model }
        else
          content_tag(:p, class: "mt-s mb-none") do
            t("decidim.questions.questions.show.sign_in_or_up",
              in: link_to(t("decidim.questions.questions.show.sign_in"), decidim.new_user_session_path),
              up: link_to(t("decidim.questions.questions.show.sign_up"), decidim.new_user_registration_path)).html_safe
          end
        end
      end

      def question_recipient_roles
        roles = []
        %w(service committee).each do |role|
          roles.push [role, t("#{role}", scope: "decidim.admin.models.participatory_process_user_role.roles")]
        end
        return roles
      end

      def question_recipient_role(question)
        t("#{question.recipient_role}", scope: "decidim.admin.models.participatory_process_user_role.roles")
      end

      def current_user_role
        return "admin" if current_user.admin
        ParticipatoryProcessUserRole.where(user: current_user, participatory_process: current_participatory_space).first.role
      end
    end
  end
end
