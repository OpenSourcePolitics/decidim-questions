# frozen_string_literal: true

module Decidim
  module Questions
    # This controller is the abstract class from which all other controllers of
    # this engine inherit.
    #
    # Note that it inherits from `Decidim::Components::BaseController`, which
    # override its layout and provide all kinds of useful methods.
    class ApplicationController < Decidim::Components::BaseController
      helper Decidim::Messaging::ConversationHelper
      helper_method :question_limit_reached?

      def question_limit
        return nil if component_settings.question_limit.zero?
        component_settings.question_limit
      end

      def question_limit_reached?
        return false unless question_limit

        questions.where(author: current_user).count >= question_limit
      end

      def questions
        Question.where(component: current_component)
      end

      def permissions_context
        {
          current_settings: try(:current_settings),
          component_settings: try(:component_settings),
          current_organization: try(:current_organization),
          current_participatory_space: try(:current_participatory_space),
          current_component: try(:current_component)
        }
      end
    end
  end
end
