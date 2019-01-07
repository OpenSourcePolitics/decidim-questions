# frozen_string_literal: true

require "spec_helper"

describe "Report Question", type: :system do
  include_context "with a component"

  let(:manifest_name) { "questions" }
  let!(:questions) { create_list(:question, 3, component: component) }
  let(:reportable) { questions.first }
  let(:reportable_path) { resource_locator(reportable).path }
  let!(:user) { create :user, :confirmed, organization: organization }

  let!(:component) do
    create(:question_component,
           manifest: manifest,
           participatory_space: participatory_process)
  end

  include_examples "reports"
end
