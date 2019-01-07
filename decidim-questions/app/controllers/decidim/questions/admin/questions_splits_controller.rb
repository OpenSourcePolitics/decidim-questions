# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      class QuestionsSplitsController < Admin::ApplicationController
        def create
          enforce_permission_to :split, :questions

          @form = form(Admin::QuestionsSplitForm).from_params(params)

          Admin::SplitQuestions.call(@form) do
            on(:ok) do |_question|
              flash[:notice] = I18n.t("questions_splits.create.success", scope: "decidim.questions.admin")
              redirect_to EngineRouter.admin_proxy(@form.target_component).root_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("questions_splits.create.invalid", scope: "decidim.questions.admin")
              redirect_to EngineRouter.admin_proxy(current_component).root_path
            end
          end
        end
      end
    end
  end
end
