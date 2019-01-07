# frozen_string_literal: true

shared_examples "merge questions" do
  let!(:questions) { create_list :question, 3, :official, component: current_component }
  let!(:target_component) { create :question_component, participatory_space: current_component.participatory_space }
  include Decidim::ComponentPathHelper

  before do
    Decidim::Questions::Question.where.not(id: questions.map(&:id)).destroy_all
  end

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
        expect(page).to have_selector(:link_or_button, "Merge into a new one")
      end

      context "when less than one question is checked" do
        before do
          page.find("#questions_bulk.js-check-all").set(false)
          page.first(".js-question-list-check").set(true)
        end

        it "does not show the merge action option" do
          expect(page).to have_no_selector(:link_or_button, "Merge into a new one")
        end
      end
    end

    context "when merge into a new one is selected from the actions dropdown" do
      before do
        click_button "Actions"
        click_button "Merge into a new one"
      end

      it "shows the component select" do
        expect(page).to have_css("#js-form-merge-questions select", count: 1)
      end

      it "shows an update button" do
        expect(page).to have_css("button#js-submit-merge-questions", count: 1)
      end

      context "when submiting the form" do
        before do
          within "#js-form-merge-questions" do
            select translated(target_component.name), from: :target_component_id_
            page.find("button#js-submit-merge-questions").click
          end
        end

        it "creates a new question" do
          expect(page).to have_content("Successfully merged the questions into a new one")
          expect(page).to have_css(".table-list tbody tr", count: 1)
          expect(page).to have_current_path(manage_component_path(target_component))
        end

        context "when merging to the same component" do
          let!(:target_component) { current_component }
          let!(:question_ids) { questions.map(&:id) }

          it "creates a new question and deletes the other ones" do
            expect(page).to have_content("Successfully merged the questions into a new one")
            expect(page).to have_css(".table-list tbody tr", count: 1)
            expect(page).to have_current_path(manage_component_path(current_component))

            question_ids.each do |id|
              expect(page).not_to have_xpath("//tr[@data-id='#{id}']")
            end
          end
        end
      end
    end
  end
end
