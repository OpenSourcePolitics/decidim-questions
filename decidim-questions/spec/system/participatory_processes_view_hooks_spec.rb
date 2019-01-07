# frozen_string_literal: true

require "spec_helper"

describe "Questions in process home", type: :system do
  include_context "with a component"
  let(:manifest_name) { "questions" }
  let(:questions_count) { 2 }
  let(:highlighted_questions) { questions_count * 2 }

  before do
    allow(Decidim::Questions.config)
      .to receive(:participatory_space_highlighted_questions_limit)
      .and_return(highlighted_questions)
  end

  context "when there are no questions" do
    it "does not show the highlighted questions section" do
      visit resource_locator(participatory_process).path
      expect(page).not_to have_css(".highlighted_questions")
    end
  end

  context "when there are questions" do
    let!(:questions) { create_list(:question, questions_count, component: component) }
    let!(:drafted_questions) { create_list(:question, questions_count, :draft, component: component) }
    let!(:hidden_questions) { create_list(:question, questions_count, :hidden, component: component) }
    let!(:withdrawn_questions) { create_list(:question, questions_count, :withdrawn, component: component) }

    it "shows the highlighted questions section" do
      visit resource_locator(participatory_process).path

      within ".highlighted_questions" do
        expect(page).to have_css(".card--question", count: questions_count)

        questions_titles = questions.map(&:title)
        drafted_questions_titles = drafted_questions.map(&:title)
        hidden_questions_titles = hidden_questions.map(&:title)
        withdrawn_questions_titles = withdrawn_questions.map(&:title)

        highlighted_questions = page.all(".card--question .card__title").map(&:text)
        expect(questions_titles).to include(*highlighted_questions)
        expect(drafted_questions_titles).not_to include(*highlighted_questions)
        expect(hidden_questions_titles).not_to include(*highlighted_questions)
        expect(withdrawn_questions_titles).not_to include(*highlighted_questions)
      end
    end

    context "and there are more questions than those that can be shown" do
      let!(:questions) { create_list(:question, highlighted_questions + 2, component: component) }

      it "shows the amount of questions configured" do
        visit resource_locator(participatory_process).path

        within ".highlighted_questions" do
          expect(page).to have_css(".card--question", count: highlighted_questions)

          questions_titles = questions.map(&:title)
          highlighted_questions = page.all(".card--question .card__title").map(&:text)
          expect(questions_titles).to include(*highlighted_questions)
        end
      end
    end
  end
end
