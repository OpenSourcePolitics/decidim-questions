# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    module Admin
      describe UpdateParticipatoryText do
        describe "call" do
          let(:current_component) do
            create(
              :question_component,
              participatory_space: create(:participatory_process)
            )
          end
          let(:questions) do
            questions = create_list(:question, 3, component: current_component)
            questions.each_with_index do |question, idx|
              level = Decidim::Questions::ParticipatoryTextSection::LEVELS.keys[idx]
              question.update(participatory_text_level: level)
            end
            questions
          end
          let(:question_modifications) do
            modifs = []
            new_positions = [3, 1, 2]
            questions.each do |question|
              modifs << Decidim::Questions::Admin::QuestionForm.new(
                id: question.id,
                position: new_positions.shift,
                title: ::Faker::Books::Lovecraft.fhtagn,
                body: ::Faker::Books::Lovecraft.fhtagn(5)
              )
            end
            modifs
          end
          let(:form) do
            instance_double(
              PreviewParticipatoryTextForm,
              current_component: current_component,
              questions: question_modifications
            )
          end
          let(:command) { described_class.new(form) }

          describe "when form modifies questions" do
            context "with valid values" do
              it "persists modifications" do
                expect { command.call }.to broadcast(:ok)
                questions.zip(question_modifications).each do |question, question_form|
                  question.reload
                  actual = {}
                  expected = {}
                  %w(position title body).each do |attr|
                    next if (attr == "body") && (question.participatory_text_level != Decidim::Questions::ParticipatoryTextSection::LEVELS[:article])
                    expected[attr] = question_form.send attr.to_sym
                    actual[attr] = question.attributes[attr]
                  end
                  expect(actual).to eq(expected)
                end
              end
            end

            context "with invalid values" do
              before do
                question_modifications.each { |question_form| question_form.title = "" }
              end

              it "does not persist modifications and broadcasts invalid" do
                failures = {}
                questions.each do |question|
                  failures[question.id] = ["Title can't be blank"]
                end
                expect { command.call }.to broadcast(:invalid, failures)
              end
            end
          end
        end
      end
    end
  end
end
