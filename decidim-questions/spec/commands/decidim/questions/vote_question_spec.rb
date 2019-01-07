# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    describe VoteQuestion do
      describe "call" do
        let(:question) { create(:question) }
        let(:current_user) { create(:user, organization: question.component.organization) }
        let(:command) { described_class.new(question, current_user) }

        context "with normal conditions" do
          it "broadcasts ok" do
            expect { command.call }.to broadcast(:ok)
          end

          it "creates a new vote for the question" do
            expect do
              command.call
            end.to change(QuestionVote, :count).by(1)
          end
        end

        context "when the vote is not valid" do
          before do
            # rubocop:disable RSpec/AnyInstance
            allow_any_instance_of(QuestionVote).to receive(:valid?).and_return(false)
            # rubocop:enable RSpec/AnyInstance
          end

          it "broadcasts invalid" do
            expect { command.call }.to broadcast(:invalid)
          end

          it "doesn't create a new vote for the question" do
            expect do
              command.call
            end.to change(QuestionVote, :count).by(0)
          end
        end

        context "when the threshold have been reached" do
          before do
            expect(question).to receive(:maximum_votes_reached?).and_return(true)
          end

          it "broadcasts invalid" do
            expect { command.call }.to broadcast(:invalid)
          end
        end

        context "when the threshold have been reached but question can accumulate more votes" do
          before do
            expect(question).to receive(:maximum_votes_reached?).and_return(true)
            expect(question).to receive(:can_accumulate_supports_beyond_threshold).and_return(true)
          end

          it "creates a new vote for the question" do
            expect do
              command.call
            end.to change(QuestionVote, :count).by(1)
          end
        end
      end
    end
  end
end
