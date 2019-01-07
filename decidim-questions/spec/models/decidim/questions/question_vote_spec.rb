# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    describe QuestionVote do
      subject { question_vote }

      let!(:organization) { create(:organization) }
      let!(:component) { create(:component, organization: organization, manifest_name: "questions") }
      let!(:participatory_process) { create(:participatory_process, organization: organization) }
      let!(:author) { create(:user, organization: organization) }
      let!(:question) { create(:question, component: component, users: [author]) }
      let!(:question_vote) { build(:question_vote, question: question, author: author) }

      it "is valid" do
        expect(question_vote).to be_valid
      end

      it "has an associated author" do
        expect(question_vote.author).to be_a(Decidim::User)
      end

      it "has an associated question" do
        expect(question_vote.question).to be_a(Decidim::Questions::Question)
      end

      it "validates uniqueness for author and question combination" do
        question_vote.save!
        expect do
          create(:question_vote, question: question, author: author)
        end.to raise_error(ActiveRecord::RecordInvalid)
      end

      context "when no author" do
        before do
          question_vote.author = nil
        end

        it { is_expected.to be_invalid }
      end

      context "when no question" do
        before do
          question_vote.question = nil
        end

        it { is_expected.to be_invalid }
      end

      context "when question and author have different organization" do
        let(:other_author) { create(:user) }
        let(:other_question) { create(:question) }

        it "is invalid" do
          question_vote = build(:question_vote, question: other_question, author: other_author)
          expect(question_vote).to be_invalid
        end
      end

      context "when question is rejected" do
        let!(:question) { create(:question, :rejected, component: component, users: [author]) }

        it { is_expected.to be_invalid }
      end
    end
  end
end
