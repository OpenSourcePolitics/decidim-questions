# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    module Admin
      describe SplitQuestions do
        describe "call" do
          let!(:questions) { Array(create(:question, component: current_component)) }
          let!(:current_component) { create(:question_component) }
          let!(:target_component) { create(:question_component, participatory_space: current_component.participatory_space) }
          let(:form) do
            instance_double(
              QuestionsSplitForm,
              current_component: current_component,
              current_organization: current_component.organization,
              target_component: target_component,
              questions: questions,
              valid?: valid,
              same_component?: same_component,
              current_user: create(:user, :admin, organization: current_component.organization)
            )
          end
          let(:command) { described_class.new(form) }
          let(:same_component) { false }

          describe "when the form is not valid" do
            let(:valid) { false }

            it "broadcasts invalid" do
              expect { command.call }.to broadcast(:invalid)
            end

            it "doesn't create the question" do
              expect do
                command.call
              end.to change(Question, :count).by(0)
            end
          end

          describe "when the form is valid" do
            let(:valid) { true }

            it "broadcasts ok" do
              expect { command.call }.to broadcast(:ok)
            end

            it "creates two questions for each original in the new component" do
              expect do
                command.call
              end.to change { Question.where(component: target_component).count }.by(2)
            end

            it "links the questions" do
              command.call
              new_questions = Question.where(component: target_component)

              linked = questions.first.linked_resources(:questions, "copied_from_component")

              expect(linked).to match_array(new_questions)
            end

            it "only copies wanted attributes" do
              command.call
              question = questions.first
              new_question = Question.where(component: target_component).last

              expect(new_question.title).to eq(question.title)
              expect(new_question.body).to eq(question.body)
              expect(new_question.creator_author).to eq(current_component.organization)
              expect(new_question.category).to eq(question.category)

              expect(new_question.state).to be_nil
              expect(new_question.answer).to be_nil
              expect(new_question.answered_at).to be_nil
              expect(new_question.reference).not_to eq(question.reference)
            end

            context "when spliting to the same component" do
              let(:same_component) { true }
              let!(:target_component) { current_component }
              let!(:questions) { create_list(:question, 2, component: current_component) }

              it "only creates one copy for each question" do
                expect do
                  command.call
                end.to change { Question.where(component: current_component).count }.by(2)
              end

              context "when the original question has links to other questions" do
                let(:previous_component) { create(:question_component, participatory_space: current_component.participatory_space) }
                let(:previous_questions) { create(:question, component: previous_component) }

                before do
                  questions.each do |question|
                    question.link_resources(previous_questions, "copied_from_component")
                  end
                end

                it "links the copy to the same links the question has" do
                  new_questions = Question.where(component: target_component).last(2)

                  new_questions.each do |question|
                    linked = question.linked_resources(:questions, "copied_from_component")
                    expect(linked).to eq([previous_questions])
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
