# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      class QuestionsMergesController < Admin::ApplicationController
        def create
          enforce_permission_to :merge, :questions

          @form = form(Admin::QuestionsMergeForm).from_params(params)

          Admin::MergeQuestions.call(@form) do
            on(:ok) do |_question|
              flash[:notice] = I18n.t("questions_merges.create.success", scope: "decidim.questions.admin")
              redirect_to EngineRouter.admin_proxy(@form.target_component).root_path
            end

            on(:invalid) do
              flash[:alert] = I18n.t("questions_merges.create.invalid", scope: "decidim.questions.admin")
              redirect_to EngineRouter.admin_proxy(current_component).root_path
            end
          end
        end
      end
    end
  end
end
