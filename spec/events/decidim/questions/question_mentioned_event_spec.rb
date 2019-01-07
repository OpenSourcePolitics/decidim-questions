# frozen_string_literal: true

require "spec_helper"

describe Decidim::Questions::QuestionMentionedEvent do
  include_context "when a simple event"

  let(:event_name) { "decidim.events.questions.question_mentioned" }
  let(:organization) { create :organization }
  let(:author) { create :user, organization: organization }

  let(:source_question) { create :question, component: create(:question_component, organization: organization) }
  let(:mentioned_question) { create :question, component: create(:question_component, organization: organization) }
  let(:resource) { source_question }
  let(:extra) do
    {
      mentioned_question_id: mentioned_question.id
    }
  end

  it_behaves_like "a simple event"

  describe "types" do
    subject { described_class }

    it "supports notifications" do
      expect(subject.types).to include :notification
    end

    it "supports emails" do
      expect(subject.types).to include :email
    end
  end

  describe "email_subject" do
    it "is generated correctly" do
      expect(subject.email_subject).to eq("Your question \"#{mentioned_question.title}\" has been mentioned")
    end
  end

  context "with content" do
    let(:content) do
      "Your question \"#{mentioned_question.title}\" has been mentioned " \
        "<a href=\"#{resource_locator(source_question).path}\">in this space</a> in the comments."
    end

    describe "email_intro" do
      it "is generated correctly" do
        expect(subject.email_intro).to eq(content)
      end
    end

    describe "notification_title" do
      it "is generated correctly" do
        expect(subject.notification_title).to include(content)
      end
    end
  end
end
