# frozen_string_literal: true

require "spec_helper"

describe Decidim::Questions::Admin::UpdateQuestion do
  let(:form_klass) { Decidim::Questions::Admin::QuestionForm }

  let(:component) { create(:question_component) }
  let(:organization) { component.organization }
  let(:user) { create :user, :admin, :confirmed, organization: organization }
  let(:form) do
    form_klass.from_params(params).with_context(context)
  end
  let(:context) do
    {
      current_organization: organization,
      current_participatory_space: component.participatory_space,
      current_user: user,
      current_component: component
    }
  end
  let(:params) do
    {
      title: question.title,
      body: question.body,
      scope_id: question.scope.try(:id),
      state: state,
      recipient: recipient,
      recipient_ids: recipient_ids,
      answer: question.answer
    }
  end
  let(:state) { "accepted" }
  let(:recipient) { "none" }
  let(:recipient_ids) { [] }

  let!(:question) { create :question, :official, state: "accepted", component: component }

  describe "call" do
    let(:command) do
      described_class.new(form, question)
    end

    describe "when the form is not valid" do
      before do
        expect(form).to receive(:invalid?).and_return(true)
      end

      it "broadcasts invalid" do
        expect { command.call }.to broadcast(:invalid)
      end

      it "doesn't update the question" do
        expect do
          command.call
        end.not_to change(question, :title)
      end
    end

    describe "when the form is valid" do
      before do
        expect(form).to be_valid
      end

      it "broadcasts ok" do
        expect { command.call }.to broadcast(:ok)
      end

      it "updates the question" do
        expect do
          command.call
        end.to change(question, :title)
      end

      it "traces the update", versioning: true do
        expect(Decidim.traceability)
          .to receive(:update!)
          .with(question, user, a_kind_of(Hash))
          .and_call_original

        expect { command.call }.to change(Decidim::ActionLog, :count)

        action_log = Decidim::ActionLog.last
        expect(action_log.version).to be_present
        expect(action_log.version.event).to eq "update"
      end

      context "when changing untraceable attrtibutes", versioning: true do
        let(:state) { "evaluating" }

        it "does not trace the update" do
          expect { command.call }.not_to change(Decidim::ActionLog, :count)
          expect(question.reload.state).to eq("evaluating")
        end
      end

      context "when it has some recipients" do
        let(:committee_user) { create :user, :confirmed, organization: organization }
        let(:state) { "evaluating" }
        let(:recipient) { "committee" }
        let(:recipient_ids) { [committee_user.id] }

        before do
          expect(form).to receive(:recipient_ids).at_least(:once).and_return(recipient_ids)
        end

        it "notifies them" do
          expect(Decidim::EventsManager).to receive(:publish).with(
            hash_including(
              event: "decidim.events.questions.forward_question",
              affected_users: array_including(
                having_attributes(
                  id: committee_user.id,
                  class: Decidim::User
                )
              )
            )
          )

          command.call
        end
      end
    end
  end
end
