# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    describe WithdrawQuestion do
      let(:question) { create(:question) }

      before do
        question.save!
      end

      describe "when current user IS the author of the question" do
        let(:current_user) { question.creator_author }
        let(:command) { described_class.new(question, current_user) }

        context "and the question has no supports" do
          it "withdraws the question" do
            expect do
              expect { command.call }.to broadcast(:ok)
            end.to change { Decidim::Questions::Question.count }.by(0)
            expect(question.state).to eq("withdrawn")
          end
        end

        context "and the question HAS some supports" do
          before do
            question.votes.create!(author: current_user)
          end

          it "is not able to withdraw the question" do
            expect do
              expect { command.call }.to broadcast(:invalid)
            end.to change { Decidim::Questions::Question.count }.by(0)
            expect(question.state).not_to eq("withdrawn")
          end
        end
      end
    end
  end
end
