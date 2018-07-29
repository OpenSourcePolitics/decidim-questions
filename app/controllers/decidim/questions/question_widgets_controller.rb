# frozen_string_literal: true

module Decidim
  module Questions
    class QuestionWidgetsController < Decidim::WidgetsController
      helper Questions::ApplicationHelper

      private

      def model
        @model ||= Question.where(component: params[:component_id]).find(params[:question_id])
      end

      def iframe_url
        @iframe_url ||= question_question_widget_url(model)
      end
    end
  end
end
