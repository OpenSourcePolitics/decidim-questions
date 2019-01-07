# frozen_string_literal: true

require "spec_helper"

describe Decidim::Questions::Admin::Permissions do
  subject { described_class.new(user, permission_action, context).permissions.allowed? }

  let(:user) { build :user }
  let(:current_component) { create(:question_component) }
  let(:question) { nil }
  let(:context) do
    {
      question: question,
      current_component: current_component,
      current_settings: current_settings,
      component_settings: component_settings
    }
  end
  let(:component_settings) do
    double(
      official_questions_enabled: official_questions_enabled?,
      question_answering_enabled: component_settings_question_answering_enabled?,
      participatory_texts_enabled?: component_settings_participatory_texts_enabled?
    )
  end
  let(:current_settings) do
    double(
      creation_enabled?: creation_enabled?,
      question_answering_enabled: current_settings_question_answering_enabled?
    )
  end
  let(:creation_enabled?) { true }
  let(:official_questions_enabled?) { true }
  let(:component_settings_question_answering_enabled?) { true }
  let(:component_settings_participatory_texts_enabled?) { true }
  let(:current_settings_question_answering_enabled?) { true }
  let(:permission_action) { Decidim::PermissionAction.new(action) }

  describe "question note creation" do
    let(:action) do
      { scope: :admin, action: :create, subject: :question_note }
    end

    context "when the space allows it" do
      it { is_expected.to eq true }
    end
  end

  describe "question creation" do
    let(:action) do
      { scope: :admin, action: :create, subject: :question }
    end

    context "when everything is OK" do
      it { is_expected.to eq true }
    end

    context "when creation is disabled" do
      let(:creation_enabled?) { false }

      it { is_expected.to eq false }
    end

    context "when official questions are disabled" do
      let(:official_questions_enabled?) { false }

      it { is_expected.to eq false }
    end
  end

  describe "question edition" do
    let(:action) do
      { scope: :admin, action: :edit, subject: :question }
    end

    context "when the question is not official" do
      let(:question) { create :question, component: current_component }

      it_behaves_like "permission is not set"
    end

    context "when the question is official" do
      let(:question) { create :question, :official, component: current_component }

      context "when everything is OK" do
        it { is_expected.to eq true }
      end

      context "when it has some votes" do
        before do
          create :question_vote, question: question
        end

        it_behaves_like "permission is not set"
      end
    end
  end

  describe "question answering" do
    let(:action) do
      { scope: :admin, action: :create, subject: :question_answer }
    end

    context "when everything is OK" do
      it { is_expected.to eq true }
    end

    context "when answering is disabled in the step level" do
      let(:current_settings_question_answering_enabled?) { false }

      it { is_expected.to eq false }
    end

    context "when answering is disabled in the component level" do
      let(:component_settings_question_answering_enabled?) { false }

      it { is_expected.to eq false }
    end
  end

  describe "update question category" do
    let(:action) do
      { scope: :admin, action: :update, subject: :question_category }
    end

    it { is_expected.to eq true }
  end

  describe "import questions from another component" do
    let(:action) do
      { scope: :admin, action: :import, subject: :questions }
    end

    it { is_expected.to eq true }
  end

  describe "import participatory texts" do
    let(:action) do
      { scope: :admin, action: :import, subject: :participatory_texts }
    end

    it { is_expected.to eq true }
  end
end
