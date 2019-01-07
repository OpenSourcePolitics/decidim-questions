# frozen_string_literal: true

require "spec_helper"
require "decidim/api/test/type_context"
require "decidim/core/test"

module Decidim
  module Questions
    describe QuestionsType, type: :graphql do
      include_context "with a graphql type"
      let(:model) { create(:question_component) }

      it_behaves_like "a component query type"

      describe "questions" do
        let!(:draft_questions) { create_list(:question, 2, :draft, component: model) }
        let!(:published_questions) { create_list(:question, 2, component: model) }
        let!(:other_questions) { create_list(:question, 2) }

        let(:query) { "{ questions { edges { node { id } } } }" }

        it "returns the published questions" do
          ids = response["questions"]["edges"].map { |edge| edge["node"]["id"] }
          expect(ids).to include(*published_questions.map(&:id).map(&:to_s))
          expect(ids).not_to include(*draft_questions.map(&:id).map(&:to_s))
          expect(ids).not_to include(*other_questions.map(&:id).map(&:to_s))
        end
      end

      describe "question" do
        let(:query) { "query Question($id: ID!){ question(id: $id) { id } }" }
        let(:variables) { { id: question.id.to_s } }

        context "when the question belongs to the component" do
          let!(:question) { create(:question, component: model) }

          it "finds the question" do
            expect(response["question"]["id"]).to eq(question.id.to_s)
          end
        end

        context "when the question doesn't belong to the component" do
          let!(:question) { create(:question, component: create(:question_component)) }

          it "returns null" do
            expect(response["question"]).to be_nil
          end
        end
      end
    end
  end
end
