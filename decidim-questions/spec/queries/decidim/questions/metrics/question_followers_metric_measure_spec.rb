# frozen_string_literal: true

require "spec_helper"

describe Decidim::Questions::Metrics::QuestionFollowersMetricMeasure do
  let(:day) { Time.zone.yesterday }
  let(:organization) { create(:organization) }
  let(:not_valid_resource) { create(:dummy_resource) }
  let(:participatory_space) { create(:participatory_process, :with_steps, organization: organization) }
  let(:questions_component) { create(:question_component, :published, participatory_space: participatory_space) }
  let(:question) { create(:question, :with_endorsements, published_at: day, component: questions_component) }
  let(:draft) { create(:collaborative_draft, published_at: day, component: questions_component) }
  let!(:follows) do
    create_list(:follow, 10, followable: question, created_at: day)
    create_list(:follow, 10, followable: draft, created_at: day)
    create_list(:follow, 10, followable: question, created_at: day - 1.week)
  end

  context "when executing class" do
    it "fails to create object with an invalid resource" do
      manager = described_class.new(day, not_valid_resource)

      expect(manager).not_to be_valid
    end

    it "calculates" do
      result = described_class.new(day, questions_component).calculate

      expect(result[:cumulative_users].count).to eq(30)
      expect(result[:quantity_users].count).to eq(20)
    end

    it "does not found any result for past days" do
      result = described_class.new(day - 1.month, questions_component).calculate

      expect(result[:cumulative_users].count).to eq(0)
      expect(result[:quantity_users].count).to eq(0)
    end
  end
end
