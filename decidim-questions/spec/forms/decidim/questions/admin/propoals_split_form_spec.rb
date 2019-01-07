# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    module Admin
      describe QuestionsSplitForm do
        subject { form }

        let(:questions) { create_list(:question, 2, component: component) }
        let(:component) { create(:question_component) }
        let(:target_component) { create(:question_component, participatory_space: component.participatory_space) }
        let(:params) do
          {
            target_component_id: [target_component.try(:id).to_s],
            question_ids: questions.map(&:id)
          }
        end

        let(:form) do
          described_class.from_params(params).with_context(
            current_component: component,
            current_participatory_space: component.participatory_space
          )
        end

        context "when everything is OK" do
          it { is_expected.to be_valid }
        end

        context "without a target component" do
          let(:target_component) { nil }

          it { is_expected.to be_invalid }
        end

        context "when not enough questions" do
          let(:questions) { [] }

          it { is_expected.to be_invalid }
        end

        context "when given a target component from another space" do
          let(:target_component) { create(:question_component) }

          it { is_expected.to be_invalid }
        end

        context "when merging to the same component" do
          let(:target_component) { component }
          let(:questions) { create_list(:question, 3, :official, component: component) }

          context "when the question is not official" do
            let(:questions) { create_list(:question, 3, component: component) }

            it { is_expected.to be_invalid }
          end

          context "when a question has a vote" do
            before do
              create(:question_vote, question: questions.sample)
            end

            it { is_expected.to be_invalid }
          end

          context "when a question has an endorsement" do
            before do
              create(:question_endorsement, question: questions.sample)
            end

            it { is_expected.to be_invalid }
          end
        end
      end
    end
  end
end
