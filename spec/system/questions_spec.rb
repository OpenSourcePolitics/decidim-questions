# frozen_string_literal: true

require "spec_helper"

describe "Questions", type: :system do
  include_context "with a component"
  let(:manifest_name) { "questions" }

  let!(:category) { create :category, participatory_space: participatory_process }
  let!(:scope) { create :scope, organization: organization }
  let!(:user) { create :user, :confirmed, organization: organization }
  let(:scoped_participatory_process) { create(:participatory_process, :with_steps, organization: organization, scope: scope) }

  let(:address) { "Carrer Pare Llaurador 113, baixos, 08224 Terrassa" }
  let(:latitude) { 40.1234 }
  let(:longitude) { 2.1234 }

  before do
    stub_geocoding(address, [latitude, longitude])
  end

  matcher :have_author do |name|
    match { |node| node.has_selector?(".author-data", text: name) }
    match_when_negated { |node| node.has_no_selector?(".author-data", text: name) }
  end

  matcher :have_creation_date do |date|
    match { |node| node.has_selector?(".author-data__extra", text: date) }
    match_when_negated { |node| node.has_no_selector?(".author-data__extra", text: date) }
  end

  context "when viewing a single question" do
    let!(:component) do
      create(:question_component,
             manifest: manifest,
             participatory_space: participatory_process)
    end

    let!(:questions) { create_list(:question, 3, component: component) }

    it "allows viewing a single question" do
      question = questions.first

      visit_component

      click_link question.title

      expect(page).to have_content(question.title)
      expect(page).to have_content(question.body)
      expect(page).to have_author(question.creator_author.name)
      expect(page).to have_content(question.reference)
      expect(page).to have_creation_date(I18n.l(question.published_at, format: :decidim_short))
    end

    context "when process is not related to any scope" do
      let!(:question) { create(:question, component: component, scope: scope) }

      it "can be filtered by scope" do
        visit_component
        click_link question.title
        expect(page).to have_content(translated(scope.name))
      end
    end

    context "when process is related to a child scope" do
      let!(:question) { create(:question, component: component, scope: scope) }
      let(:participatory_process) { scoped_participatory_process }

      it "does not show the scope name" do
        visit_component
        click_link question.title
        expect(page).to have_no_content(translated(scope.name))
      end
    end

    context "when it is an official question" do
      let!(:official_question) { create(:question, :official, component: component) }

      it "shows the author as official" do
        visit_component
        click_link official_question.title
        expect(page).to have_content("Official question")
      end
    end

    context "when it is an official meeting question" do
      let!(:official_meeting_question) { create(:question, :official_meeting, component: component) }

      it "shows the author as meeting" do
        visit_component
        click_link official_meeting_question.title
        expect(page).to have_content(translated(official_meeting_question.authors.first.title))
      end
    end

    context "when a question has comments" do
      let(:question) { create(:question, component: component) }
      let(:author) { create(:user, :confirmed, organization: component.organization) }
      let!(:comments) { create_list(:comment, 3, commentable: question) }

      it "shows the comments" do
        visit_component
        click_link question.title

        comments.each do |comment|
          expect(page).to have_content(comment.body)
        end
      end
    end

    context "when a question has been linked in a meeting" do
      let(:question) { create(:question, component: component) }
      let(:meeting_component) do
        create(:component, manifest_name: :meetings, participatory_space: question.component.participatory_space)
      end
      let(:meeting) { create(:meeting, component: meeting_component) }

      before do
        meeting.link_resources([question], "questions_from_meeting")
      end

      it "shows related meetings" do
        visit_component
        click_link question.title

        expect(page).to have_i18n_content(meeting.title)
      end
    end

    context "when a question has been linked in a result" do
      let(:question) { create(:question, component: component) }
      let(:accountability_component) do
        create(:component, manifest_name: :accountability, participatory_space: question.component.participatory_space)
      end
      let(:result) { create(:result, component: accountability_component) }

      before do
        result.link_resources([question], "included_questions")
      end

      it "shows related resources" do
        visit_component
        click_link question.title

        expect(page).to have_i18n_content(result.title)
      end
    end

    context "when a question is in evaluation" do
      let!(:question) { create(:question, :with_answer, :evaluating, component: component) }

      it "shows a badge and an answer" do
        visit_component
        click_link question.title

        expect(page).to have_content("Evaluating")

        within ".callout.secondary" do
          expect(page).to have_content("This question is being evaluated")
          expect(page).to have_i18n_content(question.answer)
        end
      end
    end

    context "when a question has been rejected" do
      let!(:question) { create(:question, :with_answer, :rejected, component: component) }

      it "shows the rejection reason" do
        visit_component
        choose "filter_state_rejected"
        page.find_link(question.title, wait: 30)
        click_link question.title

        expect(page).to have_content("Rejected")

        within ".callout.warning" do
          expect(page).to have_content("This question has been rejected")
          expect(page).to have_i18n_content(question.answer)
        end
      end
    end

    context "when a question has been accepted" do
      let!(:question) { create(:question, :with_answer, :accepted, component: component) }

      it "shows the acceptance reason" do
        visit_component
        click_link question.title

        expect(page).to have_content("Accepted")

        within ".callout.success" do
          expect(page).to have_content("This question has been accepted")
          expect(page).to have_i18n_content(question.answer)
        end
      end
    end

    context "when the questions'a author account has been deleted" do
      let(:question) { questions.first }

      before do
        Decidim::DestroyAccount.call(question.creator_author, Decidim::DeleteAccountForm.from_params({}))
      end

      it "the user is displayed as a deleted user" do
        visit_component

        click_link question.title

        expect(page).to have_content("Deleted user")
      end
    end
  end

  context "when a question has been linked in a project" do
    let(:component) do
      create(:question_component,
             manifest: manifest,
             participatory_space: participatory_process)
    end
    let(:question) { create(:question, component: component) }
    let(:budget_component) do
      create(:component, manifest_name: :budgets, participatory_space: question.component.participatory_space)
    end
    let(:project) { create(:project, component: budget_component) }

    before do
      project.link_resources([question], "included_questions")
    end

    it "shows related projects" do
      visit_component
      click_link question.title

      expect(page).to have_i18n_content(project.title)
    end
  end

  context "when listing questions in a participatory process" do
    shared_examples_for "a random question ordering" do
      let!(:lucky_question) { create(:question, component: component) }
      let!(:unlucky_question) { create(:question, component: component) }

      it "lists the questions ordered randomly by default" do
        visit_component

        expect(page).to have_selector("a", text: "Random")
        expect(page).to have_selector(".card--question", count: 2)
        expect(page).to have_selector(".card--question", text: lucky_question.title)
        expect(page).to have_selector(".card--question", text: unlucky_question.title)
        expect(page).to have_author(lucky_question.creator_author.name)
      end
    end

    it "lists all the questions" do
      create(:question_component,
             manifest: manifest,
             participatory_space: participatory_process)

      create_list(:question, 3, component: component)

      visit_component
      expect(page).to have_css(".card--question", count: 3)
    end

    describe "editable content" do
      before do
        visit_component
      end

      it_behaves_like "editable content for admins"
    end

    describe "default ordering" do
      it_behaves_like "a random question ordering"
    end

    context "when voting phase is over" do
      let!(:component) do
        create(:question_component,
               :with_votes_blocked,
               manifest: manifest,
               participatory_space: participatory_process)
      end

      let!(:most_voted_question) do
        question = create(:question, component: component)
        create_list(:question_vote, 3, question: question)
        question
      end

      let!(:less_voted_question) { create(:question, component: component) }

      before { visit_component }

      it "lists the questions ordered by votes by default" do
        expect(page).to have_selector("a", text: "Most voted")
        expect(page).to have_selector("#questions .card-grid .column:first-child", text: most_voted_question.title)
        expect(page).to have_selector("#questions .card-grid .column:last-child", text: less_voted_question.title)
      end

      it "shows a disabled vote button for each question, but no links to full questions" do
        expect(page).to have_button("Voting disabled", disabled: true, count: 2)
        expect(page).to have_no_link("View question")
      end
    end

    context "when voting is disabled" do
      let!(:component) do
        create(:question_component,
               :with_votes_disabled,
               manifest: manifest,
               participatory_space: participatory_process)
      end

      describe "order" do
        it_behaves_like "a random question ordering"
      end

      it "shows only links to full questions" do
        create_list(:question, 2, component: component)

        visit_component

        expect(page).to have_no_button("Voting disabled", disabled: true)
        expect(page).to have_no_button("Vote")
        expect(page).to have_link("View question", count: 2)
      end
    end

    context "when there are a lot of questions" do
      before do
        create_list(:question, Decidim::Paginable::OPTIONS.first + 5, component: component)
      end

      it "paginates them" do
        visit_component

        expect(page).to have_css(".card--question", count: Decidim::Paginable::OPTIONS.first)

        click_link "Next"

        expect(page).to have_selector(".pagination .current", text: "2")

        expect(page).to have_css(".card--question", count: 5)
      end
    end

    context "when filtering" do
      context "when official_questions setting is enabled" do
        before do
          component.update!(settings: { official_questions_enabled: true })
        end

        it "can be filtered by origin" do
          visit_component

          within "form.new_filter" do
            expect(page).to have_content(/Origin/i)
          end
        end

        context "with 'official' origin" do
          it "lists the filtered questions" do
            create_list(:question, 2, :official, component: component, scope: scope)
            create(:question, component: component, scope: scope)
            visit_component

            within ".filters" do
              choose "Official"
            end

            expect(page).to have_css(".card--question", count: 2)
            expect(page).to have_content("2 PROPOSALS")
          end
        end

        context "with 'citizens' origin" do
          it "lists the filtered questions" do
            create_list(:question, 2, component: component, scope: scope)
            create(:question, :official, component: component, scope: scope)
            visit_component

            within ".filters" do
              choose "Citizens"
            end

            expect(page).to have_css(".card--question", count: 2)
            expect(page).to have_content("2 PROPOSALS")
          end
        end
      end

      context "when official_questions setting is not enabled" do
        before do
          component.update!(settings: { official_questions_enabled: false })
        end

        it "cannot be filtered by origin" do
          visit_component

          within "form.new_filter" do
            expect(page).to have_no_content(/Official/i)
          end
        end
      end

      context "with scope" do
        let(:scopes_picker) { select_data_picker(:filter_scope_id, multiple: true, global_value: "global") }
        let!(:scope2) { create :scope, organization: participatory_process.organization }

        before do
          create_list(:question, 2, component: component, scope: scope)
          create(:question, component: component, scope: scope2)
          create(:question, component: component, scope: nil)
          visit_component
        end

        it "can be filtered by scope" do
          within "form.new_filter" do
            expect(page).to have_content(/Scopes/i)
          end
        end

        context "when selecting the global scope" do
          it "lists the filtered questions", :slow do
            within ".filters" do
              scope_pick scopes_picker, nil
            end

            expect(page).to have_css(".card--question", count: 1)
            expect(page).to have_content("1 PROPOSAL")
          end
        end

        context "when selecting one scope" do
          it "lists the filtered questions", :slow do
            within ".filters" do
              scope_pick scopes_picker, scope
            end

            expect(page).to have_css(".card--question", count: 2)
            expect(page).to have_content("2 PROPOSALS")
          end
        end

        context "when selecting the global scope and another scope" do
          it "lists the filtered questions", :slow do
            within ".filters" do
              scope_pick scopes_picker, scope
              scope_pick scopes_picker, nil
            end

            expect(page).to have_css(".card--question", count: 3)
            expect(page).to have_content("3 PROPOSALS")
          end
        end

        context "when modifying the selected scope" do
          it "lists the filtered questions" do
            within ".filters" do
              scope_pick scopes_picker, scope
              scope_pick scopes_picker, nil
              scope_repick scopes_picker, scope, scope2
            end

            expect(page).to have_css(".card--question", count: 2)
            expect(page).to have_content("2 PROPOSALS")
          end
        end

        context "when unselecting the selected scope" do
          it "lists the filtered questions" do
            within ".filters" do
              scope_pick scopes_picker, scope
              scope_pick scopes_picker, nil
              scope_unpick scopes_picker, scope
            end

            expect(page).to have_css(".card--question", count: 1)
            expect(page).to have_content("1 PROPOSAL")
          end
        end
      end

      context "when process is related to a scope" do
        let(:participatory_process) { scoped_participatory_process }

        it "cannot be filtered by scope" do
          visit_component

          within "form.new_filter" do
            expect(page).to have_no_content(/Scopes/i)
          end
        end
      end

      context "when question_answering component setting is enabled" do
        before do
          component.update!(settings: { question_answering_enabled: true })
        end

        context "when question_answering step setting is enabled" do
          before do
            component.update!(
              step_settings: {
                component.participatory_space.active_step.id => {
                  question_answering_enabled: true
                }
              }
            )
          end

          it "can be filtered by state" do
            visit_component

            within "form.new_filter" do
              expect(page).to have_content(/State/i)
            end
          end

          it "lists accepted questions" do
            create(:question, :accepted, component: component, scope: scope)
            visit_component

            within ".filters" do
              choose "Accepted"
            end

            expect(page).to have_css(".card--question", count: 1)
            expect(page).to have_content("1 PROPOSAL")

            within ".card--question" do
              expect(page).to have_content("ACCEPTED")
            end
          end

          it "lists the filtered questions" do
            create(:question, :rejected, component: component, scope: scope)
            visit_component

            within ".filters" do
              choose "Rejected"
            end

            expect(page).to have_css(".card--question", count: 1)
            expect(page).to have_content("1 PROPOSAL")

            within ".card--question" do
              expect(page).to have_content("REJECTED")
            end
          end
        end

        context "when question_answering step setting is disabled" do
          before do
            component.update!(
              step_settings: {
                component.participatory_space.active_step.id => {
                  question_answering_enabled: false
                }
              }
            )
          end

          it "cannot be filtered by state" do
            visit_component

            within "form.new_filter" do
              expect(page).to have_no_content(/State/i)
            end
          end
        end
      end

      context "when question_answering component setting is not enabled" do
        before do
          component.update!(settings: { question_answering_enabled: false })
        end

        it "cannot be filtered by state" do
          visit_component

          within "form.new_filter" do
            expect(page).to have_no_content(/State/i)
          end
        end
      end

      context "when the user is logged in" do
        before do
          login_as user, scope: :user
        end

        it "can be filtered by category" do
          create_list(:question, 3, component: component)
          create(:question, component: component, category: category)

          visit_component

          within "form.new_filter" do
            select category.name[I18n.locale.to_s], from: :filter_category_id
          end

          expect(page).to have_css(".card--question", count: 1)
        end
      end
    end

    context "when ordering by 'most_voted'" do
      let!(:component) do
        create(:question_component,
               :with_votes_enabled,
               manifest: manifest,
               participatory_space: participatory_process)
      end

      it "lists the questions ordered by votes" do
        most_voted_question = create(:question, component: component)
        create_list(:question_vote, 3, question: most_voted_question)
        less_voted_question = create(:question, component: component)

        visit_component

        within ".order-by" do
          expect(page).to have_selector("ul[data-dropdown-menu$=dropdown-menu]", text: "Random")
          page.find("a", text: "Random").click
          click_link "Most voted"
        end

        expect(page).to have_selector("#questions .card-grid .column:first-child", text: most_voted_question.title)
        expect(page).to have_selector("#questions .card-grid .column:last-child", text: less_voted_question.title)
      end
    end

    context "when ordering by 'recent'" do
      it "lists the questions ordered by created at" do
        older_question = create(:question, component: component, created_at: 1.month.ago)
        recent_question = create(:question, component: component)

        visit_component

        within ".order-by" do
          expect(page).to have_selector("ul[data-dropdown-menu$=dropdown-menu]", text: "Random")
          page.find("a", text: "Random").click
          click_link "Recent"
        end

        expect(page).to have_selector("#questions .card-grid .column:first-child", text: recent_question.title)
        expect(page).to have_selector("#questions .card-grid .column:last-child", text: older_question.title)
      end
    end

    context "when paginating" do
      let!(:collection) { create_list :question, collection_size, component: component }
      let!(:resource_selector) { ".card--question" }

      it_behaves_like "a paginated resource"
    end

    context "when amendments_enabled setting is enabled" do
      let!(:question) { create(:question, component: component, scope: scope) }
      let!(:emendation) { create(:question, component: component, scope: scope) }
      let!(:amendment) { create(:amendment, amendable: question, emendation: emendation) }

      before do
        component.update!(settings: { amendments_enabled: true })
        visit_component
      end

      context "with 'all' type" do
        it "lists the filtered questions" do
          find('input[id="filter_type_all"]').click

          expect(page).to have_css(".card.card--question", count: 2)
          expect(page).to have_content("2 PROPOSALS")
          expect(page).to have_content("AMENDMENT", count: 1)
        end
      end

      context "with 'questions' type" do
        it "lists the filtered questions" do
          within ".filters" do
            choose "Questions"
          end

          expect(page).to have_css(".card.card--question", count: 1)
          expect(page).to have_content("1 PROPOSAL")
          expect(page).to have_content("AMENDMENT", count: 0)
        end
      end

      context "with 'amendments' type" do
        it "lists the filtered questions" do
          within ".filters" do
            choose "Amendments"
          end

          expect(page).to have_css(".card.card--question", count: 1)
          expect(page).to have_content("1 PROPOSAL")
          expect(page).to have_content("AMENDMENT", count: 1)
        end
      end
    end
  end
end
