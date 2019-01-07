# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    describe UnvoteQuestion do
      describe "call" do
        let(:question) { create(:question) }
        let(:current_user) { create(:user, organization: question.component.organization) }
        let!(:question_vote) { create(:question_vote, author: current_user, question: question) }
        let(:command) { described_class.new(question, current_user) }

        it "broadcasts ok" do
          expect { command.call }.to broadcast(:ok)
        end

        it "deletes the question vote for that user" do
          expect do
            command.call
          end.to change(QuestionVote, :count).by(-1)
        end

        it "decrements the right score for that user" do
          Decidim::Gamification.set_score(current_user, :question_votes, 10)
          command.call
          expect(Decidim::Gamification.status_for(current_user, :question_votes).score).to eq(9)
        end
      end
    end
  end
end
