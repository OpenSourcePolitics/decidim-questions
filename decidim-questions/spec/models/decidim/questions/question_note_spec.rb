# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    describe QuestionNote do
      subject { question_note }

      let!(:organization) { create(:organization) }
      let!(:component) { create(:component, organization: organization, manifest_name: "questions") }
      let!(:participatory_process) { create(:participatory_process, organization: organization) }
      let!(:author) { create(:user, :admin, organization: organization) }
      let!(:question) { create(:question, component: component, users: [author]) }
      let!(:question_note) { build(:question_note, question: question, author: author) }

      it { is_expected.to be_valid }
      it { is_expected.to be_versioned }

      it "has an associated author" do
        expect(question_note.author).to be_a(Decidim::User)
      end

      it "has an associated question" do
        expect(question_note.question).to be_a(Decidim::Questions::Question)
      end
    end
  end
end
