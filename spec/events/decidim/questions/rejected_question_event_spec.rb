# frozen_string_literal: true

require "spec_helper"

describe Decidim::Questions::RejectedQuestionEvent do
  let(:resource) { create :question, :with_answer }
  let(:event_name) { "decidim.events.questions.question_rejected" }

  include_context "when a simple event"
  it_behaves_like "a simple event"

  describe "email_subject" do
    it "is generated correctly" do
      expect(subject.email_subject).to eq("A question you're following has been rejected")
    end
  end

  describe "email_intro" do
    it "is generated correctly" do
      expect(subject.email_intro)
        .to eq("The question \"#{resource.title}\" has been rejected. You can read the answer in this page:")
    end
  end

  describe "email_outro" do
    it "is generated correctly" do
      expect(subject.email_outro)
        .to eq("You have received this notification because you are following \"#{resource.title}\". You can unfollow it from the previous link.")
    end
  end

  describe "notification_title" do
    it "is generated correctly" do
      expect(subject.notification_title)
        .to include("The <a href=\"#{resource_path}\">#{resource.title}</a> question has been rejected")
    end
  end

  describe "resource_text" do
    it "shows the question answer" do
      expect(subject.resource_text).to eq translated(resource.answer)
    end
  end
end
