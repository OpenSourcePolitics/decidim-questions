# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    module Admin
      describe AnswerQuestion do
        describe "call" do
          let(:question) { create(:question) }
          let(:current_user) { create(:user, :admin) }
          let(:form) { QuestionAnswerForm.from_params(form_params).with_context(current_user: current_user) }
          let(:form_params) do
            {
              state: "rejected", answer: { en: "Foo" }
            }
          end

          let(:command) { described_class.new(form, question) }

          describe "when the form is not valid" do
            before do
              expect(form).to receive(:invalid?).and_return(true)
            end

            it "broadcasts invalid" do
              expect { command.call }.to broadcast(:invalid)
            end

            it "doesn't update the question" do
              expect(question).not_to receive(:update!)
              command.call
            end
          end

          describe "when the form is valid" do
            before do
              expect(form).to receive(:invalid?).and_return(false)
            end

            it "broadcasts ok" do
              expect { command.call }.to broadcast(:ok)
            end

            it "updates the question" do
              command.call

              expect(question.reload).to be_answered
            end

            context "when accepted" do
              before do
                form.state = "accepted"
              end

              it "updates the gamification score for their authors" do
                expect { command.call }.to change {
                  Decidim::Gamification.status_for(question.authors.first, :accepted_questions).score
                }.by(1)
              end
            end

            context "when rejected" do
              before do
                form.state = "rejected"
              end

              it "doesn't update the gamification score for their authors" do
                expect { command.call }.to change {
                  Decidim::Gamification.status_for(question.authors.first, :accepted_questions).score
                }.by(0)
              end
            end

            it "traces the action", versioning: true do
              expect(Decidim.traceability)
                .to receive(:perform_action!)
                .with("answer", question, form.current_user)
                .and_call_original

              expect { command.call }.to change(Decidim::ActionLog, :count)
              action_log = Decidim::ActionLog.last
              expect(action_log.version).to be_present
              expect(action_log.version.event).to eq "update"
            end

            context "when the state changes" do
              it "notifies the question followers" do
                follower = create(:user, organization: question.organization)
                create(:follow, followable: question, user: follower)

                expect(Decidim::EventsManager)
                  .to receive(:publish)
                  .with(
                    event: "decidim.events.questions.question_rejected",
                    event_class: Decidim::Questions::RejectedQuestionEvent,
                    resource: question,
                    affected_users: match_array([question.creator_author]),
                    followers: match_array([follower])
                  )

                command.call
              end
            end
          end
        end
      end
    end
  end
end
