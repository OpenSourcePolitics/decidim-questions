# frozen_string_literal: true

require "spec_helper"

describe "Index Question Notes", type: :system do
  let(:component) { create(:question_component) }
  let(:organization) { component.organization }

  let(:manifest_name) { "questions" }
  let(:question) { create(:question, component: component) }
  let(:participatory_space) { component.participatory_space }

  let(:body) { "New awesome body" }
  let(:question_notes_count) { 5 }

  let!(:question_notes) do
    create_list(
      :question_note,
      question_notes_count,
      question: question
    )
  end

  include_context "when managing a component as an admin"

  before do
    visit current_path + "questions/#{question.id}/question_notes"
  end

  it "shows question notes for the current question" do
    question_notes.each do |question_note|
      expect(page).to have_content(question_note.author.name)
      expect(page).to have_content(question_note.body)
    end
    expect(page).to have_selector("form")
  end

  context "when the form has a text inside body" do
    it "creates a question note ", :slow do
      within ".new_question_note" do
        fill_in :question_note_body, with: body

        find("*[type=submit]").click
      end

      expect(page).to have_admin_callout("successfully")

      within ".comment-thread .card:last-child" do
        expect(page).to have_content("New awesome body")
      end
    end
  end

  context "when the form hasn't text inside body" do
    let(:body) { nil }

    it "don't create a question note", :slow do
      within ".new_question_note" do
        fill_in :question_note_body, with: body

        find("*[type=submit]").click
      end

      expect(page).to have_content("There's an error in this field.")
    end
  end
end
