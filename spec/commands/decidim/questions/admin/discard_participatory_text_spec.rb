# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    module Admin
      describe DiscardParticipatoryText do
        describe "call" do
          let(:current_component) do
            create(
              :question_component,
              participatory_space: create(:participatory_process)
            )
          end
          let(:questions) do
            create_list(:question, 3, :draft, component: current_component)
          end
          let(:command) { described_class.new(current_component) }

          describe "when discarding" do
            it "removes all drafts" do
              expect { command.call }.to broadcast(:ok)
              questions = Decidim::Questions::Question.drafts.where(component: current_component)
              expect(questions).to be_empty
            end
          end
        end
      end
    end
  end
end
