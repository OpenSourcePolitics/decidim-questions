# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      class QuestionsMovesController < Admin::ApplicationController
        def create
          enforce_permission_to :move, :questions

          @form = form(Admin::QuestionsMoveForm).from_params(params)

          Admin::MoveQuestions.call(@form, current_user) do
            on(:ok) do |_question|
              flash[:notice] = I18n.t("questions_moves.create.success", scope: "decidim.questions.admin")
              redirect_to EngineRouter.admin_proxy(current_component).root_path
            end

            on(:invalid) do
              flash[:alert] = I18n.t("questions_moves.create.invalid", scope: "decidim.questions.admin")
              redirect_to EngineRouter.admin_proxy(current_component).root_path
            end
          end
        end
      end
    end
  end
end
