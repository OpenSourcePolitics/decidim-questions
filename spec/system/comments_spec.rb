# frozen_string_literal: true

require "spec_helper"

describe "Comments", type: :system do
  let!(:component) { create(:question_component, organization: organization) }
  let!(:author) { create(:user, :confirmed, organization: organization) }
  let!(:commentable) { create(:question, component: component, users: [author]) }

  let(:resource_path) { resource_locator(commentable).path }

  include_examples "comments"
end
