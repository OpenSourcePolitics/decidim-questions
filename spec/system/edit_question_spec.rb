# frozen_string_literal: true

require "spec_helper"

describe "Edit questions", type: :system do
  include_context "with a component"
  let(:manifest_name) { "questions" }

  let!(:user) { create :user, :confirmed, organization: participatory_process.organization }
  let!(:another_user) { create :user, :confirmed, organization: participatory_process.organization }
  let!(:question) { create :question, users: [user], component: component }

  before do
    switch_to_host user.organization.host
  end

  describe "editing my own question" do
    let(:new_title) { "This is my question new title" }
    let(:new_body) { "This is my question new body" }

    before do
      login_as user, scope: :user
    end

    it "can be updated" do
      visit_component

      click_link question.title
      click_link "Edit question"

      expect(page).to have_content "EDIT PROPOSAL"

      within "form.edit_question" do
        fill_in :question_title, with: new_title
        fill_in :question_body, with: new_body
        click_button "Send"
      end

      expect(page).to have_content(new_title)
      expect(page).to have_content(new_body)
    end

    context "when updating with wrong data" do
      let(:component) { create(:question_component, :with_creation_enabled, :with_attachments_allowed, participatory_space: participatory_process) }

      it "returns an error message" do
        visit_component

        click_link question.title
        click_link "Edit question"

        expect(page).to have_content "EDIT PROPOSAL"

        within "form.edit_question" do
          fill_in :question_body, with: "A"
          click_button "Send"
        end

        expect(page).to have_content("is using too many capital letters (over 25% of the text), is too short (under 15 characters)")
      end

      it "keeps the submitted values" do
        visit_component

        click_link question.title
        click_link "Edit question"

        expect(page).to have_content "EDIT PROPOSAL"

        within "form.edit_question" do
          fill_in :question_title, with: "A title with a #hashtag"
          fill_in :question_body, with: "Ỳü"
        end
        click_button "Send"

        expect(page).to have_selector("input[value='A title with a #hashtag']")
        expect(page).to have_content("Ỳü")
      end
    end
  end

  describe "editing someone else's question" do
    before do
      login_as another_user, scope: :user
    end

    it "renders an error" do
      visit_component

      click_link question.title
      expect(page).to have_no_content("Edit question")
      visit current_path + "/edit"

      expect(page).to have_content("not authorized")
    end
  end

  describe "editing my question outside the time limit" do
    let!(:question) { create :question, users: [user], component: component, created_at: 1.hour.ago }

    before do
      login_as another_user, scope: :user
    end

    it "renders an error" do
      visit_component

      click_link question.title
      expect(page).to have_no_content("Edit question")
      visit current_path + "/edit"

      expect(page).to have_content("not authorized")
    end
  end
end
