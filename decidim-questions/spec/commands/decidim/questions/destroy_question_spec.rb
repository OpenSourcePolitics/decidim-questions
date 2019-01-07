# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    describe DestroyQuestion do
      describe "call" do
        let(:component) { create(:question_component) }
        let(:organization) { component.organization }
        let(:current_user) { create(:user, organization: organization) }
        let(:other_user) { create(:user, organization: organization) }
        let!(:question) { create :question, component: component, users: [current_user] }
        let(:question_draft) { create(:question, :draft, component: component, users: [current_user]) }
        let!(:question_draft_other) { create :question, component: component, users: [other_user] }

        it "broadcasts ok" do
          expect { described_class.call(question_draft, current_user) }.to broadcast(:ok)
          expect { question_draft.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "broadcasts invalid when the question is not a draft" do
          expect { described_class.call(question, current_user) }.to broadcast(:invalid)
        end

        it "broadcasts invalid when the question_draft is from another author" do
          expect { described_class.call(question_draft_other, current_user) }.to broadcast(:invalid)
        end
      end
    end
  end
end
