# frozen_string_literal: true

require "spec_helper"

describe "Admin manages particpatory texts", type: :system do
  let(:manifest_name) { "questions" }
  let(:participatory_space_path) do
    decidim_admin_participatory_processes.edit_participatory_process_path(participatory_process)
  end

  include_context "when managing a component as an admin"

  before do
    component.update!(
      settings: { participatory_texts_enabled: true }
    )
  end

  def visit_participatory_texts
    visit_component_admin
    find("#js-other-actions-wrapper a#participatory_texts").click
    expect(page).to have_content "PREVIEW PARTICIPATORY TEXT"
  end

  def import_document
    find("a#import-doc").click
    expect(page).to have_content "ADD DOCUMENT"

    fill_in_i18n(
      :import_participatory_text_title,
      "#import-title",
      ca: "Algun text participatiu",
      en: "Some participatory text",
      es: "Un texto participativo"
    )
    fill_in_i18n(
      :import_participatory_text_description,
      "#import-desc",
      ca: "La descripció d'algun text participatiu",
      en: "The description of some participatory text",
      es: "La descripción de algún texto participativo"
    )
    attach_file :import_participatory_text_document, Decidim::Dev.asset("participatory_text.md")
    click_button "Upload document"
    expect(page).to have_content "Congratulations, the following sections have been parsed from the imported document, they have been converted to questions. Now you can review and adjust whatever you need before publishing."
    expect(page).to have_content "PREVIEW PARTICIPATORY TEXT"
  end

  def validate_occurrences(sections: nil, subsections: nil, articles: nil)
    expect(page).to have_content "Section:", count: sections if sections
    expect(page).to have_content "Subsection:", count: subsections if subsections
    expect(page).to have_content "Article", count: articles if articles
  end

  def move_some_sections; end

  def publish_participatory_text
    find("button[name=commit]").click
    expect(page).to have_content "All questions have been published"
  end

  def validate_published
    questions = Decidim::Questions::Question.where(component: current_component)
    titles = [
      "The great title for a new law",
      "A co-creation process to create creative creations",
      "1", "2",
      "Creative consensus for the Creation",
      "3", "4", "5",
      "Creation accountability",
      "6",
      "What should be accounted",
      "7", "8",
      "Following up accounted results",
      "9", "10", "11", "12", "13",
      "Summary",
      "14", "15"
    ]
    expect(questions.count).to eq(titles.size)
    expect(questions.published.count).to eq(titles.size)
    expect(questions.published.order(:position).pluck(:title)).to eq(titles)
  end

  def edit_participatory_text_body(index, new_body)
    elem = Array.wrap(find("#participatory-text li"))[index]
    elem.find("a.accordion-title").click

    elem.fill_in(
      "Body",
      with: new_body
    )
  end

  def save_participatory_text_drafts
    # click twice as clicking once provokes flaky tests
    click_button "Save draft"
    find("button[name=save_draft]").click
    expect(page).to have_content "Participatory text updated successfully."
    expect(page).to have_content "PREVIEW PARTICIPATORY TEXT"
  end

  def discard_participatory_text_drafts
    page.accept_alert "Are you sure to discard the whole participatory text draft?" do
      click_link "Discard all"
    end
    expect(page).to have_content "All Participatory text drafts have been discarded."
    expect(page).to have_content "PREVIEW PARTICIPATORY TEXT"
  end

  def edit_participatory_text_body(index, new_body)
    elem = Array.wrap(find("#participatory-text li"))[index]
    elem.find("a.accordion-title").click

    elem.fill_in(
      "Body",
      with: new_body
    )
  end

  def save_participatory_text_drafts
    # click twice as clicking once provokes flaky tests
    click_button "Save draft"
    find("button[name=save_draft]").click
    expect(page).to have_content "Participatory text updated successfully."
    expect(page).to have_content "PREVIEW PARTICIPATORY TEXT"
  end

  def discard_participatory_text_drafts
    page.accept_alert "Are you sure to discard the whole participatory text draft?" do
      click_link "Discard all"
    end
    expect(page).to have_content "All Participatory text drafts have been discarded."
    expect(page).to have_content "PREVIEW PARTICIPATORY TEXT"
  end

  describe "importing partipatory texts from a document" do
    it "creates questions" do
      visit_participatory_texts
      import_document
      validate_occurrences(sections: 2, subsections: 5, articles: 15)
      move_some_sections
      publish_participatory_text
      validate_published
    end
  end

  describe "accessing participatory texts in draft mode" do
    let!(:question) { create :question, :draft, component: current_component, participatory_text_level: "section" }

    it "renders only draft questions" do
      visit_participatory_texts
      validate_occurrences(sections: 1, subsections: 0, articles: 0)
    end
  end

  describe "discarding participatory texts in draft mode" do
    let!(:questions) { create_list(:question, 5, :draft, component: current_component, participatory_text_level: "article") }

    it "removes all questions in draft mode" do
      visit_participatory_texts
      validate_occurrences(sections: 0, subsections: 0, articles: 5)
      discard_participatory_text_drafts
      validate_occurrences(sections: 0, subsections: 0, articles: 0)
    end
  end

  describe "updating participatory texts in draft mode" do
    let!(:question) { create :question, :draft, component: current_component, participatory_text_level: "article" }
    let!(:new_body) { Faker::Lorem.sentences(3).join("\n") }

    it "persists changes and all questions remain as drafts" do
      visit_participatory_texts
      validate_occurrences(sections: 0, subsections: 0, articles: 1)
      edit_participatory_text_body(0, new_body)
      save_participatory_text_drafts
      validate_occurrences(sections: 0, subsections: 0, articles: 1)
      question.reload
      expect(question.body.delete("\r")).to eq(new_body)
    end
  end

  describe "updating participatory texts in draft mode" do
    let!(:question) { create :question, :draft, component: current_component, participatory_text_level: "article" }
    let!(:new_body) { Faker::Lorem.unique.sentences(3).join("\n") }

    it "persists changes and all questions remain as drafts" do
      visit_participatory_texts
      validate_occurrences(sections: 0, subsections: 0, articles: 1)
      edit_participatory_text_body(0, new_body)
      save_participatory_text_drafts
      validate_occurrences(sections: 0, subsections: 0, articles: 1)
      question.reload
      expect(question.body.delete("\r")).to eq(new_body)
    end
  end
end
