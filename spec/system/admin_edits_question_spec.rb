# frozen_string_literal: true

require "spec_helper"

describe "Admin edits questions", type: :system do
  let(:manifest_name) { "questions" }
  let(:organization) { participatory_process.organization }
  let!(:user) { create :user, :admin, :confirmed, organization: organization }
  let!(:question) { create :question, :official, component: component }
  let(:creation_enabled?) { true }

  include_context "when managing a component as an admin"

  before do
    component.update!(
      step_settings: {
        component.participatory_space.active_step.id => {
          creation_enabled: creation_enabled?
        }
      }
    )
  end

  describe "editing an official question" do
    let(:new_title) { "This is my question new title" }
    let(:new_body) { "This is my question new body" }

    it "can be updated" do
      visit_component_admin

      find("a.action-icon--edit-question").click
      expect(page).to have_content "UPDATE QUESTION"

      fill_in "Title", with: new_title
      fill_in "Body", with: new_body
      click_button "Update"

      preview_window = window_opened_by { find("a.action-icon--preview").click }

      within_window preview_window do
        expect(page).to have_content(new_title)
        expect(page).to have_content(new_body)
      end
    end

    context "when the question has some votes" do
      before do
        create :question_vote, question: question
      end

      it "doesn't let the user edit it" do
        visit_component_admin

        expect(page).to have_content(question.title)
        expect(page).to have_no_css("a.action-icon--edit-question")
        visit current_path + "questions/#{question.id}/edit"

        expect(page).to have_content("not authorized")
      end
    end
  end

  describe "editing a non-official question" do
    let!(:question) { create :question, users: [user], component: component }

    it "renders an error" do
      visit_component_admin

      expect(page).to have_content(question.title)
      expect(page).to have_no_css("a.action-icon--edit-question")
      visit current_path + "questions/#{question.id}/edit"

      expect(page).to have_content("not authorized")
    end
  end
end
