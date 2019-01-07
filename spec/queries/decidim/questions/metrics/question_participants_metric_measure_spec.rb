# frozen_string_literal: true

require "spec_helper"

describe Decidim::Questions::Metrics::QuestionParticipantsMetricMeasure do
  let(:day) { Time.zone.yesterday }
  let(:organization) { create(:organization) }
  let(:not_valid_resource) { create(:dummy_resource) }
  let(:participatory_space) { create(:participatory_process, :with_steps, organization: organization) }

  let(:questions_component) { create(:question_component, :published, participatory_space: participatory_space) }
  let!(:question) { create(:question, :with_endorsements, published_at: day, component: questions_component) }
  let!(:old_question) { create(:question, :with_endorsements, published_at: day - 1.week, component: questions_component) }
  let!(:question_votes) { create_list(:question_vote, 10, created_at: day, question: question) }
  let!(:old_question_votes) { create_list(:question_vote, 5, created_at: day - 1.week, question: old_question) }
  let!(:question_endorsements) { create_list(:question_endorsement, 5, created_at: day, question: question) }
  # TOTAL Participants for Questions:
  #  Cumulative: 22 ( 2 question, 15 votes, 5 endorsements )
  #  Quantity: 16 ( 1 question, 10 votes, 5 endorsements )

  context "when executing class" do
    it "fails to create object with an invalid resource" do
      manager = described_class.new(day, not_valid_resource)

      expect(manager).not_to be_valid
    end

    it "calculates" do
      result = described_class.new(day, questions_component).calculate

      expect(result[:cumulative_users].count).to eq(22)
      expect(result[:quantity_users].count).to eq(16)
    end

    it "does not found any result for past days" do
      result = described_class.new(day - 1.month, questions_component).calculate

      expect(result[:cumulative_users].count).to eq(0)
      expect(result[:quantity_users].count).to eq(0)
    end
  end
end
