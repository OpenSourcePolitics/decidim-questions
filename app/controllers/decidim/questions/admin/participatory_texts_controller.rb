# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # This controller manages the participatory texts area.
      class ParticipatoryTextsController < Admin::ApplicationController
        helper_method :question
        helper Decidim::Questions::ParticipatoryTextsHelper

        def index
          @drafts = Question.where(component: current_component).drafts.order(:position)
          @preview_form = form(Admin::PreviewParticipatoryTextForm).instance
          @preview_form.from_models(@drafts)
        end

        def new_import
          enforce_permission_to :import, :participatory_texts
          participatory_text = Decidim::Questions::ParticipatoryText.find_by(component: current_component)
          @import = form(Admin::ImportParticipatoryTextForm).from_model(participatory_text)
        end

        def import
          enforce_permission_to :import, :participatory_texts
          @import = form(Admin::ImportParticipatoryTextForm).from_params(params)

          Admin::ImportParticipatoryText.call(@import) do
            on(:ok) do
              flash[:notice] = I18n.t("participatory_texts.import.success", scope: "decidim.questions.admin")
              redirect_to participatory_texts_path(component_id: current_component.id, assembly_slug: "asdf")
            end

            on(:invalid) do
              flash.now[:alert] = I18n.t("participatory_texts.import.invalid", scope: "decidim.questions.admin")
              render action: "new_import"
            end
          end
        end

        def publish
          enforce_permission_to :publish, :participatory_texts
          form_params = params.require(:preview_participatory_text).permit!
          @preview_form = form(Admin::PreviewParticipatoryTextForm).from_params(questions: form_params[:questions_attributes]&.values)

          PublishParticipatoryText.call(@preview_form) do
            on(:ok) do
              flash[:notice] = I18n.t("participatory_texts.publish.success", scope: "decidim.questions.admin")
              redirect_to questions_path
            end

            on(:invalid) do |failures|
              alert_msg = [I18n.t("participatory_texts.publish.invalid", scope: "decidim.questions.admin")]
              failures.each_pair { |id, msg| alert_msg << "ID:[#{id}] #{msg}" }
              flash.now[:alert] = alert_msg.join("<br/>").html_safe
              index
              render action: "index"
            end
          end
        end
      end
    end
  end
end
