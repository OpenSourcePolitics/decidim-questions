# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    describe PublishQuestionEvent do
      let(:resource) { create :question, title: "A nice question" }
      let(:event_name) { "decidim.events.questions.question_published" }

      include_context "when a simple event"
      it_behaves_like "a simple event"

      describe "resource_text" do
        it "returns the question body" do
          expect(subject.resource_text).to eq(resource.body)
        end
      end

      describe "email_subject" do
        it "is generated correctly" do
          expect(subject.email_subject).to eq("New question \"#{resource.title}\" by @#{author.nickname}")
        end
      end

      describe "email_intro" do
        it "is generated correctly" do
          expect(subject.email_intro)
            .to eq("#{author.name} @#{author.nickname}, who you are following, has published a new question called \"#{resource.title}\". Check it out and contribute:")
        end
      end

      describe "email_outro" do
        it "is generated correctly" do
          expect(subject.email_outro)
            .to eq("You have received this notification because you are following @#{author.nickname}. You can stop receiving notifications following the previous link.")
        end
      end

      describe "notification_title" do
        it "is generated correctly" do
          expect(subject.notification_title)
            .to include("The <a href=\"#{resource_path}\">#{resource.title}</a> question was published by ")

          expect(subject.notification_title)
            .to include("<a href=\"/profiles/#{author.nickname}\">#{author.name} @#{author.nickname}</a>.")
        end
      end

      context "when the target are the participatory space followers" do
        let(:event_name) { "decidim.events.questions.question_published_for_space" }
        let(:extra) { { participatory_space: true } }

        include_context "when a simple event"
        it_behaves_like "a simple event"

        describe "email_subject" do
          it "is generated correctly" do
            expect(subject.email_subject).to eq("New question \"#{resource.title}\" added to #{participatory_space_title}")
          end
        end

        describe "email_intro" do
          it "is generated correctly" do
            expect(subject.email_intro).to eq("The question \"A nice question\" has been added to \"#{participatory_space_title}\" that you are following.")
          end
        end

        describe "email_outro" do
          it "is generated correctly" do
            expect(subject.email_outro)
              .to include("You have received this notification because you are following \"#{participatory_space_title}\"")
          end
        end

        describe "notification_title" do
          it "is generated correctly" do
            expect(subject.notification_title)
              .to eq("The question <a href=\"#{resource_path}\">A nice question</a> has been added to #{participatory_space_title}")
          end
        end
      end
    end
  end
end
