# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    module Admin
      describe MergeQuestions do
        describe "call" do
          let!(:questions) { create_list(:question, 3, component: current_component) }
          let!(:current_component) { create(:question_component) }
          let!(:target_component) { create(:question_component, participatory_space: current_component.participatory_space) }
          let(:form) do
            instance_double(
              QuestionsMergeForm,
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

            it "creates a question in the new component" do
              expect do
                command.call
              end.to change { Question.where(component: target_component).count }.by(1)
            end

            it "links the questions" do
              command.call
              question = Question.where(component: target_component).last

              linked = question.linked_resources(:questions, "copied_from_component")

              expect(linked).to match_array(questions)
            end

            it "only merges wanted attributes" do
              command.call
              new_question = Question.where(component: target_component).last
              question = questions.first

              expect(new_question.title).to eq(question.title)
              expect(new_question.body).to eq(question.body)
              expect(new_question.creator_author).to eq(current_component.organization)
              expect(new_question.category).to eq(question.category)

              expect(new_question.state).to be_nil
              expect(new_question.answer).to be_nil
              expect(new_question.answered_at).to be_nil
              expect(new_question.reference).not_to eq(question.reference)
            end

            context "when merging from the same component" do
              let(:same_component) { true }
              let(:target_component) { current_component }

              it "deletes the original questions" do
                command.call
                question_ids = questions.map(&:id)

                expect(Decidim::Questions::Question.where(id: question_ids)).to be_empty
              end

              it "links the merged question to the links the other questions had" do
                other_component = create(:question_component, participatory_space: current_component.participatory_space)
                other_questions = create_list(:question, 3, component: other_component)

                questions.each_with_index do |question, index|
                  question.link_resources(other_questions[index], "copied_from_component")
                end

                command.call

                question = Question.where(component: target_component).last
                linked = question.linked_resources(:questions, "copied_from_component")
                expect(linked).to match_array(other_questions)
              end
            end
          end
        end
      end
    end
  end
end
