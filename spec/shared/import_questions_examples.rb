# frozen_string_literal: true

shared_examples "import questions" do
  let!(:questions) { create_list :question, 3, :accepted, component: origin_component }
  let!(:rejected_questions) { create_list :question, 3, :rejected, component: origin_component }
  let!(:origin_component) { create :question_component, participatory_space: current_component.participatory_space }
  include Decidim::ComponentPathHelper

  it "imports questions from one component to another" do
    click_link "Import from another component"

    within ".import_questions" do
      select origin_component.name["en"], from: :questions_import_origin_component_id
      check "Accepted"
      check :questions_import_import_questions
    end

    click_button "Import questions"

    expect(page).to have_content("3 questions successfully imported")

    questions.each do |question|
      expect(page).to have_content(question.title["en"])
    end

    expect(page).to have_current_path(manage_component_path(current_component))
  end
end
