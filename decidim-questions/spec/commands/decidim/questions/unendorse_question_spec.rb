# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    describe UnendorseQuestion do
      describe "User unendorse question" do
        let(:endorsement) { create(:question_endorsement) }
        let(:command) { described_class.new(endorsement.question, endorsement.author) }

        it "broadcasts ok" do
          expect(endorsement).to be_valid
          expect { command.call }.to broadcast :ok
        end

        it "Removes the endorsement" do
          expect(endorsement).to be_valid
          expect do
            command.call
          end.to change(QuestionEndorsement, :count).by(-1)
        end

        it "Decreases the endorsements counter by one" do
          question = endorsement.question
          expect(QuestionEndorsement.count).to eq(1)
          expect do
            command.call
            question.reload
          end.to change { question.question_endorsements_count }.by(-1)
        end
      end

      describe "Organization unendorses question" do
        let(:endorsement) { create(:user_group_question_endorsement) }
        let(:command) { described_class.new(endorsement.question, endorsement.author, endorsement.user_group) }

        it "broadcasts ok" do
          expect(endorsement).to be_valid
          expect { command.call }.to broadcast :ok
        end

        it "Removes the endorsement" do
          expect(endorsement).to be_valid
          expect do
            command.call
          end.to change(QuestionEndorsement, :count).by(-1)
        end

        it "Do not decreases the endorsement counter by one" do
          expect(endorsement).to be_valid
          command.call

          question = endorsement.question
          question.reload
          expect(question.question_endorsements_count).to be_zero
        end
      end
    end
  end
end
