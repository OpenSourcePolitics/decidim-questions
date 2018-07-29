# frozen_string_literal: true

module Decidim
  module Questions
    # Simple helper to handle markup variations for question endorsements partials
    module QuestionEndorsementsHelper
      # Returns the css classes used for question endorsements count in both questions list and show pages
      #
      # from_questions_list - A boolean to indicate if the template is rendered from the questions list page
      #
      # Returns a hash with the css classes for the count number and label
      def endorsements_count_classes(from_questions_list)
        return { number: "card__support__number", label: "" } if from_questions_list
        { number: "extra__suport-number", label: "extra__suport-text" }
      end

      # Returns the css classes used for question endorsement button in both questions list and show pages
      #
      # from_questions_list - A boolean to indicate if the template is rendered from the questions list page
      #
      # Returns a string with the value of the css classes.
      def endorsement_button_classes(from_questions_list)
        return "small" if from_questions_list
        "small compact light button--sc expanded"
      end

      # Public: Checks if endorsement are enabled in this step.
      #
      # Returns true if enabled, false otherwise.
      def endorsements_enabled?
        current_settings.endorsements_enabled
      end

      # Public: Checks if endorsements are blocked in this step.
      #
      # Returns true if blocked, false otherwise.
      def endorsements_blocked?
        current_settings.endorsements_blocked
      end

      # Public: Checks if the current user is allowed to endorse in this step.
      #
      # Returns true if the current user can endorse, false otherwise.
      def current_user_can_endorse?
        current_user && endorsements_enabled? && !endorsements_blocked?
      end

      # Public: Checks if the card for endorsements should be rendered.
      #
      # Returns true if the endorsements card should be rendered, false otherwise.
      def show_endorsements_card?
        endorsements_enabled?
      end

      def endorsement_identity_presenter(endorsement)
        if endorsement.user_group
          Decidim::UserGroupPresenter.new(endorsement.user_group)
        else
          Decidim::UserPresenter.new(endorsement.author)
        end
      end

      # Public: Renders a button to endorse the given question.
      # To override the translation for both buttons: endorse and unendorse (use to be the name of the user/user_group).
      #
      # @params (mandatory): question, from_questions_list
      # @params (optional) : user_group, btn_label
      def endorsement_button(question, from_questions_list, btn_label = nil, user_group = nil)
        current_endorsement_url = question_question_endorsement_path(
          question_id: question,
          from_questions_list: from_questions_list,
          user_group_id: user_group&.id
        )
        endorse_label = btn_label || t("decidim.questions.question_endorsements_helper.endorsement_button.endorse")
        unendorse_label = btn_label || t("decidim.questions.question_endorsements_helper.endorsement_button.already_endorsed")

        render partial: "decidim/questions/questions/endorsement_button", locals: { question: question,
                                                                                    from_questions_list: from_questions_list, user_group: user_group,
                                                                                    current_endorsement_url: current_endorsement_url,
                                                                                    endorse_label: endorse_label, unendorse_label: unendorse_label }
      end

      #
      # Public: Checks if the given Question has been endorsed by all identities of the user.
      #
      # @param question: The Question from which endorsements will be checked against.
      # @param user:     The user whose identities and endorsements  will be checked against.
      #
      def fully_endorsed?(question, user)
        return false unless user

        user_group_endorsements = user.user_groups.verified.all? { |user_group| question.endorsed_by?(user, user_group) }

        user_group_endorsements && question.endorsed_by?(user)
      end

      # Public: Renders an identity for endorsement.
      #
      # @params (mandatory): question, from_questions_list
      # @params (mandatory): user, the user that is endorsing at the end.
      # @params (optional) : user_group, the user_group on behalf of which the endorsement is being done
      def render_endorsement_identity(question, user, user_group = nil)
        current_endorsement_url = question_question_endorsement_path(
          question_id: question,
          from_questions_list: false,
          user_group_id: user_group&.id,
          authenticity_token: form_authenticity_token
        )
        presenter = if user_group
                      Decidim::UserGroupPresenter.new(user_group)
                    else
                      Decidim::UserPresenter.new(user)
                    end
        selected = question.endorsed_by?(user, user_group)
        http_method = selected ? :delete : :post
        render partial: "decidim/questions/question_endorsements/identity", locals:
        { identity: presenter, selected: selected, current_endorsement_url: current_endorsement_url, http_method: http_method }
      end
    end
  end
end
