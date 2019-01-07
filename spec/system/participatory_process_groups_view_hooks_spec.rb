# frozen_string_literal: true

require "spec_helper"

describe "Questions in process group home", type: :system do
  include_context "with a component"
  let(:manifest_name) { "questions" }
  let(:questions_count) { 2 }
  let(:highlighted_questions) { questions_count * 2 }

  let!(:participatory_process_group) do
    create(
      :participatory_process_group,
      participatory_processes: [participatory_process],
      organization: organization,
      name: { en: "Name", ca: "Nom", es: "Nombre" }
    )
  end

  before do
    allow(Decidim::Questions.config)
      .to receive(:process_group_highlighted_questions_limit)
      .and_return(highlighted_questions)
  end

  context "when there are no questions" do
    it "does not show the highlighted questions section" do
      visit decidim_participatory_processes.participatory_process_group_path(participatory_process_group)
      expect(page).not_to have_css(".highlighted_questions")
    end
  end

  context "when there are questions" do
    let!(:questions) { create_list(:question, questions_count, component: component) }
    let!(:drafted_questions) { create_list(:question, questions_count, :draft, component: component) }
    let!(:hidden_questions) { create_list(:question, questions_count, :hidden, component: component) }
    let!(:withdrawn_questions) { create_list(:question, questions_count, :withdrawn, component: component) }

    it "shows the highlighted questions section" do
      visit decidim_participatory_processes.participatory_process_group_path(participatory_process_group)

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
        visit decidim_participatory_processes.participatory_process_group_path(participatory_process_group)

        within ".highlighted_questions" do
          expect(page).to have_css(".card--question", count: highlighted_questions)

          questions_titles = questions.map(&:title)
          highlighted_questions = page.all(".card--question .card__title").map(&:text)
          expect(questions_titles).to include(*highlighted_questions)
        end
      end
    end

    context "when scopes enabled and questions not in top scope" do
      let(:main_scope) { create(:scope, organization: organization) }
      let(:child_scope) { create(:scope, parent: main_scope) }

      before do
        participatory_process.update!(scopes_enabled: true, scope: main_scope)
        questions.each { |question| question.update!(scope: child_scope) }
      end

      it "shows a tag with the questions scope" do
        visit decidim_participatory_processes.participatory_process_group_path(participatory_process_group)

        expect(page).to have_selector(".tags", text: child_scope.name["en"], count: questions_count)
      end
    end
  end
end
