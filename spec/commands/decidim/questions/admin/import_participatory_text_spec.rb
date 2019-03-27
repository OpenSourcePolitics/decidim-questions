# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    module Admin
      describe ImportParticipatoryText do
        describe "call" do
          let!(:document_file) { IO.read(Decidim::Dev.asset(document_name)) }
          let(:current_component) do
            create(
              :question_component,
              participatory_space: create(:participatory_process)
            )
          end
          let(:form_doc) do
            instance_double(File,
                            blank?: false)
          end
          let(:form) do
            instance_double(
              ImportParticipatoryTextForm,
              current_component: current_component,
              title: {},
              description: {},
              document: form_doc,
              document_text: document_file,
              document_type: document_type,
              current_user: create(:user),
              valid?: valid
            )
          end
          let(:command) { described_class.new(form) }

          shared_examples "import participatory_text succeeds" do
            it "broadcasts ok and creates the questions" do
              sections = 2
              sub_sections = 5
              expect { command.call }.to(
                broadcast(:ok) &&
                change { ParticipatoryText.where(component: current_component).count }.by(1) &&
                change { Question.where(component: current_component, participatory_text_level: Decidim::Questions::ParticipatoryTextSection::LEVELS[:section]).count }.by(sections) &&
                change { Question.where(component: current_component, participatory_text_level: Decidim::Questions::ParticipatoryTextSection::LEVELS[:sub_section]).count }.by(sub_sections) &&
                change { Question.where(component: current_component, participatory_text_level: Decidim::Questions::ParticipatoryTextSection::LEVELS[:article]).count }.by(articles)
              )
            end
          end

          describe "when the form is not valid" do
            let(:valid) { false }
            let(:document_name) { "participatory_text.md" }
            let(:document_type) { "text/markdown" }

            it "broadcasts invalid" do
              expect { command.call }.to broadcast(:invalid)
            end

            it "doesn't create any question" do
              expect do
                command.call
              end.to change(Question, :count).by(0)
            end
          end

          describe "when the form is valid" do
            let(:valid) { true }

            context "with markdown document" do
              let(:document_name) { "participatory_text.md" }
              let(:document_type) { "text/markdown" }
              let(:articles) { 15 }

              it_behaves_like "import participatory_text succeeds"
            end

            context "with odt document" do
              let(:document_name) { "participatory_text.odt" }
              let(:document_type) { "application/vnd.oasis.opendocument.text" }
              let(:articles) { 15 }

              it_behaves_like "import participatory_text succeeds"
            end
          end
        end
      end
    end
  end
end
