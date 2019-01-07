# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    describe QuestionsController, type: :controller do
      routes { Decidim::Questions::Engine.routes }

      let(:user) { create(:user, :confirmed, organization: component.organization) }

      let(:params) do
        {
          component_id: component.id
        }
      end

      before do
        request.env["decidim.current_organization"] = component.organization
        request.env["decidim.current_participatory_space"] = component.participatory_space
        request.env["decidim.current_component"] = component
        sign_in user
      end

      describe "GET index" do
        context "when participatory texts are disabled" do
          let(:component) { create(:question_component) }

          it "sorts questions by search defaults" do
            get :index
            expect(response).to have_http_status(:ok)
            expect(subject).to render_template(:index)
            expect(assigns(:questions).order_values).to eq(["RANDOM()"])
          end
        end

        context "when participatory texts are enabled" do
          let(:component) { create(:question_component, :with_participatory_texts_enabled) }

          it "sorts questions by position" do
            get :index
            expect(response).to have_http_status(:ok)
            expect(subject).to render_template(:participatory_text)
            expect(assigns(:questions).order_values.first.expr.name).to eq(:position)
          end
        end
      end

      describe "GET new" do
        let(:component) { create(:question_component, :with_creation_enabled) }

        context "when NO draft questions exist" do
          it "renders the empty form" do
            get :new, params: params
            expect(response).to have_http_status(:ok)
            expect(subject).to render_template(:new)
          end
        end

        context "when draft questions exist from other users" do
          let!(:others_draft) { create(:question, :draft, component: component) }

          it "renders the empty form" do
            get :new, params: params
            expect(response).to have_http_status(:ok)
            expect(subject).to render_template(:new)
          end
        end
      end

      describe "POST create" do
        context "when creation is not enabled" do
          let(:component) { create(:question_component) }

          it "raises an error" do
            post :create, params: params

            expect(flash[:alert]).not_to be_empty
          end
        end

        context "when creation is enabled" do
          let(:component) { create(:question_component, :with_creation_enabled) }

          it "creates a question" do
            post :create, params: params.merge(
              title: "Lorem ipsum dolor sit amet, consectetur adipiscing elit",
              body: "Ut sed dolor vitae purus volutpat venenatis. Donec sit amet sagittis sapien. Curabitur rhoncus ullamcorper feugiat. Aliquam et magna metus."
            )

            expect(flash[:notice]).not_to be_empty
            expect(response).to have_http_status(:found)
          end
        end
      end

      describe "withdraw a question" do
        let(:component) { create(:question_component, :with_creation_enabled) }

        context "when an authorized user is withdrawing a question" do
          let(:question) { create(:question, component: component, users: [user]) }

          it "withdraws the question" do
            put :withdraw, params: params.merge(id: question.id)

            expect(flash[:notice]).not_to be_empty
            expect(response).to have_http_status(:found)
          end
        end

        describe "when current user is NOT the author of the question" do
          let(:current_user) { create(:user, organization: component.organization) }
          let(:question) { create(:question, component: component, users: [current_user]) }

          context "and the question has no supports" do
            it "is not able to withdraw the question" do
              expect(WithdrawQuestion).not_to receive(:call)

              put :withdraw, params: params.merge(id: question.id)

              expect(flash[:alert]).not_to be_empty
              expect(response).to have_http_status(:found)
            end
          end
        end
      end
    end
  end
end
