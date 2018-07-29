# frozen_string_literal: true

module Decidim
  module Questions
    # Custom helpers, scoped to the questions engine.
    #
    module QuestionCellsHelper
      include Decidim::Questions::ApplicationHelper
      include Decidim::Questions::Engine.routes.url_helpers
      include Decidim::LayoutHelper
      include Decidim::ApplicationHelper
      include Decidim::TranslationsHelper
      include Decidim::ResourceReferenceHelper
      include Decidim::TranslatableAttributes
      include Decidim::CardHelper

      delegate :title, :state, :answered?, :withdrawn?, to: :model

      def actionable?
        questions_controller? && index_action? && (current_settings.votes_enabled? || current_settings.votes_weight_enabled?) && !model.draft?
      end

      def questions_controller?
        context[:controller].class.to_s == "Decidim::Questions::QuestionsController"
      end

      def index_action?
        context[:controller].action_name == "index"
      end

      def current_settings
        model.component.current_settings
      end

      def component_settings
        model.component.settings
      end

      def current_component
        model.component
      end

      def from_context
        @options[:from]
      end

      def badge_name
        humanize_question_state state
      end

      def state_classes
        case state
        when "accepted"
          ["success"]
        when "rejected"
          ["alert"]
        when "evaluating"
          ["warning"]
        when "withdrawn"
          ["alert"]
        else
          ["muted"]
        end
      end
    end
  end
end
