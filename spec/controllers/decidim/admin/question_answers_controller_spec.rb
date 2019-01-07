# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    module Admin
      describe QuestionAnswersController, type: :controller do
        routes { Decidim::Questions::AdminEngine.routes }

        let(:component) { question.component }
        let(:question) { create(:question) }
        let(:user) { create(:user, :confirmed, :admin, organization: component.organization) }

        let(:params) do
          {
            id: question.id,
            question_id: question.id,
            component_id: component.id,
            participatory_process_slug: component.participatory_space.slug,
            state: "rejected"
          }
        end

        before do
          request.env["decidim.current_organization"] = component.organization
          request.env["decidim.current_component"] = component
          sign_in user
        end

        describe "PUT update" do
          context "when the command fails" do
            it "renders the edit template" do
              put :update, params: params

              expect(response).to render_template(:edit)
            end
          end
        end
      end
    end
  end
end
