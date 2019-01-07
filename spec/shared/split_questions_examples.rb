# frozen_string_literal: true

shared_examples "split questions" do
  let!(:questions) { create_list :question, 3, component: current_component }
  let!(:target_component) { create :question_component, participatory_space: current_component.participatory_space }
  include Decidim::ComponentPathHelper

  context "when selecting questions" do
    before do
      visit current_path
      page.find("#questions_bulk.js-check-all").set(true)
    end

    context "when click the bulk action button" do
      before do
        click_button "Actions"
      end

      it "shows the change action option" do
        expect(page).to have_selector(:link_or_button, "Split questions")
      end
    end

    context "when split into a new one is selected from the actions dropdown" do
      before do
        page.find("#questions_bulk.js-check-all").set(false)
        page.first(".js-question-list-check").set(true)

        click_button "Actions"
        click_button "Split questions"
      end

      it "shows the component select" do
        expect(page).to have_css("#js-form-split-questions select", count: 1)
      end

      it "shows an update button" do
        expect(page).to have_css("button#js-submit-split-questions", count: 1)
      end

      context "when submiting the form" do
        before do
          within "#js-form-split-questions" do
            select translated(target_component.name), from: :target_component_id_
            page.find("button#js-submit-split-questions").click
          end
        end

        it "creates a new question" do
          expect(page).to have_content("Successfully splitted the questions into new ones")
          expect(page).to have_css(".table-list tbody tr", count: 2)
        end
      end
    end
  end
end
