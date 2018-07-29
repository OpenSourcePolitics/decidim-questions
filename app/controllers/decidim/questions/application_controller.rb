# frozen_string_literal: true

module Decidim
  module Questions
    # This controller is the abstract class from which all other controllers of
    # this engine inherit.
    #
    # Note that it inherits from `Decidim::Components::BaseController`, which
    # override its layout and provide all kinds of useful methods.
    class ApplicationController < Decidim::Components::BaseController
      helper Decidim::DecidimFormHelper
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
    end
  end
end
