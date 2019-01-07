# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    describe QuestionVotesController, type: :controller do
      routes { Decidim::Questions::Engine.routes }

      let(:question) { create(:question, component: component) }
      let(:user) { create(:user, :confirmed, organization: component.organization) }

      let(:params) do
        {
          question_id: question.id,
          component_id: component.id
        }
      end

      before do
        request.env["decidim.current_organization"] = component.organization
        request.env["decidim.current_participatory_space"] = component.participatory_space
        request.env["decidim.current_component"] = component
        sign_in user
      end

      describe "POST create" do
        context "with votes enabled" do
          let(:component) do
            create(:question_component, :with_votes_enabled)
          end

          it "allows voting" do
            expect do
              post :create, format: :js, params: params
            end.to change(QuestionVote, :count).by(1)

            expect(QuestionVote.last.author).to eq(user)
            expect(QuestionVote.last.question).to eq(question)
          end
        end

        context "with votes disabled" do
          let(:component) do
            create(:question_component)
          end

          it "doesn't allow voting" do
            expect do
              post :create, format: :js, params: params
            end.not_to change(QuestionVote, :count)

            expect(flash[:alert]).not_to be_empty
            expect(response).to have_http_status(:found)
          end
        end

        context "with votes enabled but votes blocked" do
          let(:component) do
            create(:question_component, :with_votes_blocked)
          end

          it "doesn't allow voting" do
            expect do
              post :create, format: :js, params: params
            end.not_to change(QuestionVote, :count)

            expect(flash[:alert]).not_to be_empty
            expect(response).to have_http_status(:found)
          end
        end
      end

      describe "destroy" do
        before do
          create(:question_vote, question: question, author: user)
        end

        context "with vote limit enabled" do
          let(:component) do
            create(:question_component, :with_votes_enabled, :with_vote_limit)
          end

          it "deletes the vote" do
            expect do
              delete :destroy, format: :js, params: params
            end.to change(QuestionVote, :count).by(-1)

            expect(QuestionVote.count).to eq(0)
          end
        end

        context "with vote limit disabled" do
          let(:component) do
            create(:question_component, :with_votes_enabled)
          end

          it "deletes the vote" do
            expect do
              delete :destroy, format: :js, params: params
            end.to change(QuestionVote, :count).by(-1)

            expect(QuestionVote.count).to eq(0)
          end
        end
      end
    end
  end
end
