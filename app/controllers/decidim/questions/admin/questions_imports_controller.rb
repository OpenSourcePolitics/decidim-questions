# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      class QuestionsImportsController < Admin::ApplicationController
        def new
          enforce_permission_to :import, :questions

          @form = form(Admin::QuestionsImportForm).instance
        end

        def create
          enforce_permission_to :import, :questions

          @form = form(Admin::QuestionsImportForm).from_params(params)

          Admin::ImportQuestions.call(@form) do
            on(:ok) do |questions|
              flash[:notice] = I18n.t("questions_imports.create.success", scope: "decidim.questions.admin", number: questions.length)
              redirect_to EngineRouter.admin_proxy(current_component).root_path
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("questions_imports.create.invalid", scope: "decidim.questions.admin")
              render action: "new"
            end
          end
        end
      end
    end
  end
end
