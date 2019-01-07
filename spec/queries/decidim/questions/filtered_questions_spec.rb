# frozen_string_literal: true

require "spec_helper"

describe Decidim::Questions::FilteredQuestions do
  let(:organization) { create(:organization) }
  let(:participatory_process) { create(:participatory_process, organization: organization) }
  let(:component) { create(:question_component, participatory_space: participatory_process) }
  let(:another_component) { create(:question_component, participatory_space: participatory_process) }

  let(:questions) { create_list(:question, 3, component: component) }
  let(:old_questions) { create_list(:question, 3, component: component, created_at: 10.days.ago) }
  let(:another_questions) { create_list(:question, 3, component: another_component) }

  it "returns questions included in a collection of components" do
    expect(described_class.for([component, another_component])).to match_array questions.concat(old_questions, another_questions)
  end

  it "returns questions created in a date range" do
    expect(described_class.for([component, another_component], 2.weeks.ago, 1.week.ago)).to match_array old_questions
  end
end
