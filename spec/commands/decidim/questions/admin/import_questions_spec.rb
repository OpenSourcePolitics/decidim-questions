# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    module Admin
      describe ImportQuestions do
        describe "call" do
          let!(:question) { create(:question, :accepted) }
          let(:current_component) do
            create(
              :question_component,
              participatory_space: question.component.participatory_space
            )
          end
          let(:form) do
            instance_double(
              QuestionsImportForm,
              origin_component: question.component,
              current_component: current_component,
              current_organization: current_component.organization,
              states: states,
              current_user: create(:user),
              valid?: valid
            )
          end
          let(:states) { ["accepted"] }
          let(:command) { described_class.new(form) }

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

            it "creates the questions" do
              expect do
                command.call
              end.to change { Question.where(component: current_component).count }.by(1)
            end

            context "when a question was already imported" do
              let(:second_question) { create(:question, :accepted, component: question.component) }

              before do
                command.call
                second_question
              end

              it "doesn't import it again" do
                expect do
                  command.call
                end.to change { Question.where(component: current_component).count }.by(1)

                titles = Question.where(component: current_component).map(&:title)
                expect(titles).to match_array([question.title, second_question.title])
              end
            end

            it "links the questions" do
              command.call

              linked = question.linked_resources(:questions, "copied_from_component")
              new_question = Question.where(component: current_component).last

              expect(linked).to include(new_question)
            end

            it "only imports wanted attributes" do
              command.call

              new_question = Question.where(component: current_component).last
              expect(new_question.title).to eq(question.title)
              expect(new_question.body).to eq(question.body)
              expect(new_question.creator_author).to eq(current_component.organization)
              expect(new_question.category).to eq(question.category)

              expect(new_question.state).to be_nil
              expect(new_question.answer).to be_nil
              expect(new_question.answered_at).to be_nil
              expect(new_question.reference).not_to eq(question.reference)
            end

            describe "question states" do
              let(:states) { %w(not_answered rejected) }

              before do
                create(:question, :rejected, component: question.component)
                create(:question, component: question.component)
              end

              it "only imports questions from the selected states" do
                expect do
                  command.call
                end.to change { Question.where(component: current_component).count }.by(2)

                expect(Question.where(component: current_component).pluck(:title)).not_to include(question.title)
              end
            end
          end
        end
      end
    end
  end
end
