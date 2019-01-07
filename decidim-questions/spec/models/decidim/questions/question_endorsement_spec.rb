# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    describe QuestionEndorsement do
      subject { question_endorsement }

      let!(:organization) { create(:organization) }
      let!(:component) { create(:component, organization: organization, manifest_name: "questions") }
      let!(:participatory_process) { create(:participatory_process, organization: organization) }
      let!(:author) { create(:user, organization: organization) }
      let!(:user_group) { create(:user_group, verified_at: Time.current, organization: organization, users: [author]) }
      let!(:question) { create(:question, component: component, users: [author]) }
      let!(:question_endorsement) do
        build(:question_endorsement, question: question, author: author,
                                     user_group: user_group)
      end

      it "is valid" do
        expect(question_endorsement).to be_valid
      end

      it "has an associated author" do
        expect(question_endorsement.author).to be_a(Decidim::User)
      end

      it "has an associated question" do
        expect(question_endorsement.question).to be_a(Decidim::Questions::Question)
      end

      it "validates uniqueness for author and user_group and question combination" do
        question_endorsement.save!
        expect do
          create(:question_endorsement, question: question, author: author,
                                        user_group: user_group)
        end.to raise_error(ActiveRecord::RecordInvalid)
      end

      context "when no author" do
        before do
          question_endorsement.author = nil
        end

        it { is_expected.to be_invalid }
      end

      context "when no user_group" do
        before do
          question_endorsement.user_group = nil
        end

        it { is_expected.to be_valid }
      end

      context "when no question" do
        before do
          question_endorsement.question = nil
        end

        it { is_expected.to be_invalid }
      end

      context "when question and author have different organization" do
        let(:other_author) { create(:user) }
        let(:other_question) { create(:question) }

        it "is invalid" do
          question_endorsement = build(:question_endorsement, question: other_question, author: other_author)
          expect(question_endorsement).to be_invalid
        end
      end

      context "when question is rejected" do
        let!(:question) { create(:question, :rejected, component: component, users: [author]) }

        it { is_expected.to be_invalid }
      end

      context "when retrieving for_listing" do
        before do
          question_endorsement.save!
        end

        let!(:other_user_group) { create(:user_group, verified_at: Time.current, organization: author.organization, users: [author]) }
        let!(:other_question_endorsement_1) do
          create(:question_endorsement, question: question, author: author)
        end
        let!(:other_question_endorsement_2) do
          create(:question_endorsement, question: question, author: author, user_group: other_user_group)
        end

        it "sorts user_grup endorsements first and then by created_at" do
          expected_sorting = [
            question_endorsement.id, other_question_endorsement_2.id,
            other_question_endorsement_1.id
          ]
          expect(question.endorsements.for_listing.pluck(:id)).to eq(expected_sorting)
        end
      end
    end
  end
end
