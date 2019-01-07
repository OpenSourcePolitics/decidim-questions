# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    module Admin
      describe UpdateQuestionCategory do
        describe "call" do
          let(:organization) { create(:organization) }

          let!(:question) { create :question }
          let!(:questions) { create_list(:question, 3, component: question.component) }
          let!(:category_one) { create :category, participatory_space: question.component.participatory_space }
          let!(:category) { create :category, participatory_space: question.component.participatory_space }

          context "with no category" do
            it "broadcasts invalid_category" do
              expect { described_class.call(nil, question.id) }.to broadcast(:invalid_category)
            end
          end

          context "with no questions" do
            it "broadcasts invalid_question_ids" do
              expect { described_class.call(category.id, nil) }.to broadcast(:invalid_question_ids)
            end
          end

          describe "with a category and questions" do
            context "when the category is the same as the question's category" do
              before do
                question.update!(category: category)
              end

              it "doesn't update the question" do
                expect(question).not_to receive(:update!)
                described_class.call(question.category.id, question.id)
              end
            end

            context "when the category is diferent from the question's category" do
              before do
                questions.each { |p| p.update!(category: category_one) }
              end

              it "broadcasts update_questions_category" do
                expect { described_class.call(category.id, questions.pluck(:id)) }.to broadcast(:update_questions_category)
              end

              it "updates the question" do
                described_class.call(category.id, question.id)

                expect(question.reload.category).to eq(category)
              end
            end
          end
        end
      end
    end
  end
end
