# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    describe EndorseQuestion do
      let(:question) { create(:question) }
      let(:current_user) { create(:user, organization: question.component.organization) }

      describe "User endorses Question" do
        let(:command) { described_class.new(question, current_user) }

        context "when in normal conditions" do
          it "broadcasts ok" do
            expect { command.call }.to broadcast(:ok)
          end

          it "creates a new endorsement for the question" do
            expect do
              command.call
            end.to change(QuestionEndorsement, :count).by(1)
          end

          it "notifies all followers of the endorser that the question has been endorsed" do
            follower = create(:user, organization: question.organization)
            create(:follow, followable: current_user, user: follower)
            author_follower = create(:user, organization: question.organization)
            create(:follow, followable: question.authors.first, user: author_follower)

            expect(Decidim::EventsManager)
              .to receive(:publish)
              .with(
                event: "decidim.events.questions.question_endorsed",
                event_class: Decidim::Questions::QuestionEndorsedEvent,
                resource: question,
                followers: [follower],
                extra: {
                  endorser_id: current_user.id
                }
              )

            command.call
          end
        end

        context "when the endorsement is not valid" do
          before do
            question.update(answered_at: Time.current, state: "rejected")
          end

          it "broadcasts invalid" do
            expect { command.call }.to broadcast(:invalid)
          end

          it "doesn't create a new endorsement for the question" do
            expect do
              command.call
            end.not_to change(QuestionEndorsement, :count)
          end
        end
      end

      describe "Organization endorses Question" do
        let(:user_group) { create(:user_group, verified_at: Time.current, users: [current_user]) }
        let(:command) { described_class.new(question, current_user, user_group.id) }

        context "when in normal conditions" do
          it "broadcasts ok" do
            expect { command.call }.to broadcast :ok
          end

          it "Creates an endorsement" do
            expect do
              command.call
            end.to change(QuestionEndorsement, :count).by(1)
          end
        end

        context "when the endorsement is not valid" do
          before do
            question.update(answered_at: Time.current, state: "rejected")
          end

          it "Do not increase the endorsements counter by one" do
            command.call
            question.reload
            expect(question.question_endorsements_count).to be_zero
          end
        end
      end
    end
  end
end
