# frozen_string_literal: true

require "spec_helper"

describe Decidim::Questions::Admin::UpdateQuestionCategoryEvent do
  let(:resource) { create :question }
  let(:event_name) { "decidim.events.questions.question_update_category" }

  include_context "when a simple event"
  it_behaves_like "a simple event"

  describe "email_subject" do
    it "is generated correctly" do
      expect(subject.email_subject).to eq("The #{resource.title} question category has been updated")
    end
  end

  describe "email_intro" do
    it "is generated correctly" do
      expect(subject.email_intro)
        .to eq("An admin has updated the category of your question \"#{resource.title}\", check it out:")
    end
  end

  describe "email_outro" do
    it "is generated correctly" do
      expect(subject.email_outro)
        .to eq("You have received this notification because you are the author of the question.")
    end
  end

  describe "notification_title" do
    it "is generated correctly" do
      expect(subject.notification_title)
        .to include("The <a href=\"#{resource_path}\">#{resource.title}</a> question category has been updated by an admin.")
    end
  end
end
