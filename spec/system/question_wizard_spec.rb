# frozen_string_literal: true

require "spec_helper"

describe "Question", type: :system do
  include_context "with a component"
  let(:manifest_name) { "questions" }
  let(:organization) { create :organization }

  let!(:category) { create :category, participatory_space: participatory_process }
  let!(:scope) { create :scope, organization: organization }
  let!(:user) { create :user, :confirmed, organization: organization }
  let(:scoped_participatory_process) { create(:participatory_process, :with_steps, organization: organization, scope: scope) }

  let(:address) { "Plaça Santa Jaume, 1, 08002 Barcelona" }
  let(:latitude) { 41.3825 }
  let(:longitude) { 2.1772 }

  let(:question_title) { "More sidewalks and less roads" }
  let(:question_body) { "Cities need more people, not more cars" }

  let!(:component) do
    create(:question_component,
           :with_creation_enabled,
           manifest: manifest,
           participatory_space: participatory_process)
  end

  context "when creating a new question" do
    before do
      login_as user, scope: :user
      visit_component
      click_link "New question"
    end

    context "when in step_1: Start" do
      it "show current step_1 highlighted" do
        within ".wizard__steps" do
          expect(page).to have_css(".step--active", count: 1)
          expect(page).to have_css(".step--past", count: 0)
          expect(page).to have_css(".step--active.step_1")
        end
      end

      it "fill in title and body" do
        within ".card__content form" do
          fill_in :question_title, with: question_title
          fill_in :question_body, with: question_body
          find("*[type=submit]").click
        end
      end
    end

    context "when in step_2: Compare" do
      context "with similar results" do
        before do
          create(:question, title: "More sidewalks and less roads", body: "Cities need more people, not more cars", component: component)
          create(:question, title: "More sidewalks and less roadways", body: "Green is always better", component: component)
          visit_component
          click_link "New question"
          within ".new_question" do
            fill_in :question_title, with: question_title
            fill_in :question_body, with: question_body

            find("*[type=submit]").click
          end
        end

        it "show previous and current step_2 highlighted" do
          within ".wizard__steps" do
            expect(page).to have_css(".step--active", count: 1)
            expect(page).to have_css(".step--past", count: 1)
            expect(page).to have_css(".step--active.step_2")
          end
        end

        it "shows similar questions" do
          expect(page).to have_css(".card--question", text: "More sidewalks and less roads")
          expect(page).to have_css(".card--question", count: 2)
        end

        it "show continue button" do
          expect(page).to have_content("My question is different")
        end
      end

      context "without similar results" do
        before do
          visit_component
          click_link "New question"
          within ".new_question" do
            fill_in :question_title, with: question_title
            fill_in :question_body, with: question_body

            find("*[type=submit]").click
          end
        end

        it "redirects to the complete step" do
          within ".section-heading" do
            expect(page).to have_content("COMPLETE YOUR PROPOSAL")
          end
          expect(page).to have_css(".edit_question")
        end

        it "shows no similar question found callout" do
          within ".flash.callout.success" do
            expect(page).to have_content("Well done! No similar questions found")
          end
        end
      end
    end

    context "when in step_3: Complete" do
      before do
        visit_component
        click_link "New question"
        within ".new_question" do
          fill_in :question_title, with: question_title
          fill_in :question_body, with: question_body

          find("*[type=submit]").click
        end
      end

      it "show previous and current step_3 highlighted" do
        within ".wizard__steps" do
          expect(page).to have_css(".step--active", count: 1)
          expect(page).to have_css(".step--past", count: 2)
          expect(page).to have_css(".step--active.step_3")
        end
      end

      it "show form and submit button" do
        expect(page).to have_field("Title", with: question_title)
        expect(page).to have_field("Body", with: question_body)
        expect(page).to have_button("Send")
      end
    end

    context "when in step_4: Publish" do
      let!(:question_draft) { create(:question, :draft, users: [user], component: component, title: question_title, body: question_body) }
      let!(:preview_question_path) do
        Decidim::EngineRouter.main_proxy(component).question_path(question_draft) + "/preview"
      end

      before do
        visit preview_question_path
      end

      it "show current step_4 highlighted" do
        within ".wizard__steps" do
          expect(page).to have_css(".step--active", count: 1)
          expect(page).to have_css(".step--past", count: 3)
          expect(page).to have_css(".step--active.step_4")
        end
      end

      it "shows a preview" do
        expect(page).to have_css(".card.card--question", count: 1)
      end

      it "shows a publish button" do
        expect(page).to have_selector("button", text: "Publish")
      end

      it "shows a modify question link" do
        expect(page).to have_selector("a", text: "Modify the question")
      end
    end

    context "when editing a question draft" do
      context "when in step_4: edit question draft" do
        let!(:question_draft) { create(:question, :draft, users: [user], component: component, title: question_title, body: question_body) }
        let!(:edit_draft_question_path) do
          Decidim::EngineRouter.main_proxy(component).question_path(question_draft) + "/edit_draft"
        end

        before do
          visit edit_draft_question_path
        end

        it "show current step_4 highlighted" do
          within ".wizard__steps" do
            expect(page).to have_css(".step--active", count: 1)
            expect(page).to have_css(".step--past", count: 2)
            expect(page).to have_css(".step--active.step_3")
          end
        end

        it "can discard the draft" do
          within ".card__content" do
            expect(page).to have_content("Discard this draft")
            click_link "Discard this draft"
          end

          page.accept_alert

          within_flash_messages do
            expect(page).to have_content "successfully"
          end
          expect(page).to have_css(".step--active.step_1")
        end

        it "renders a Preview button" do
          within ".card__content" do
            expect(page).to have_content("Preview")
          end
        end
      end
    end
  end
end
