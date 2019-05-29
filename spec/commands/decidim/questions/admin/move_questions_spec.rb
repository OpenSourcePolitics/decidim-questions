# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    module Admin
      describe MoveQuestions do
        describe "call" do
          let!(:questions) { Array(create(:question, component: current_component)) }
          let!(:current_component) { create(:question_component) }
          let!(:target_component) { create(:question_component, participatory_space: current_component.participatory_space) }
          let!(:current_user) { create(:user, :admin, organization: current_component.organization) }
          let(:form) do
            instance_double(
              QuestionsMoveForm,
              current_component: current_component,
              current_organization: current_component.organization,
              target_component: target_component,
              questions: questions,
              valid?: valid,
              current_user: current_user
            )
          end
          let(:command) { described_class.new(form, current_user) }
          let(:same_component) { false }

          describe "when the form is not valid" do
            let(:valid) { false }

            it "broadcasts invalid" do
              expect { command.call }.to broadcast(:invalid)
            end

            it "doesn't move the questions" do
              command.call

              questions.each do |question|
                expect(question.component).to eq(current_component)
              end
            end
          end

          describe "when the form is valid" do
            let(:valid) { true }

            it "broadcasts ok" do
              expect { command.call }.to broadcast(:ok)
            end

            it "moves the questions to a new component" do
              command.call
              questions.each do |question|
                expect(question.component).to eq(target_component)
              end
            end
          end
        end
      end
    end
  end
end
