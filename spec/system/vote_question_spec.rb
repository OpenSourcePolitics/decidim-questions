# frozen_string_literal: true

require "spec_helper"

describe "Vote Question", type: :system, slow: true do
  include_context "with a component"
  let(:manifest_name) { "questions" }

  let!(:questions) { create_list(:question, 3, component: component) }
  let!(:question) { Decidim::Questions::Question.find_by(component: component) }
  let!(:user) { create :user, :confirmed, organization: organization }

  def expect_page_not_to_include_votes
    expect(page).to have_no_button("Vote")
    expect(page).to have_no_css(".card__support__data span", text: "0 VOTES")
  end

  context "when votes are not enabled" do
    context "when the user is not logged in" do
      it "doesn't show the vote question button and counts" do
        visit_component
        expect_page_not_to_include_votes

        click_link question.title
        expect_page_not_to_include_votes
      end
    end

    context "when the user is logged in" do
      before do
        login_as user, scope: :user
      end

      it "doesn't show the vote question button and counts" do
        visit_component
        expect_page_not_to_include_votes

        click_link question.title
        expect_page_not_to_include_votes
      end
    end
  end

  context "when votes are blocked" do
    let!(:component) do
      create(:question_component,
             :with_votes_blocked,
             manifest: manifest,
             participatory_space: participatory_process)
    end

    it "shows the vote count and the vote button is disabled" do
      visit_component
      expect_page_not_to_include_votes
    end
  end

  context "when votes are enabled" do
    let!(:component) do
      create(:question_component,
             :with_votes_enabled,
             manifest: manifest,
             participatory_space: participatory_process)
    end

    context "when the user is not logged in" do
      it "is given the option to sign in" do
        visit_component

        within ".card__support", match: :first do
          click_button "Vote"
        end

        expect(page).to have_css("#loginModal", visible: true)
      end
    end

    context "when the user is logged in" do
      before do
        login_as user, scope: :user
      end

      context "when the question is not voted yet" do
        before do
          visit_component
        end

        it "is able to vote the question" do
          within "#question-#{question.id}-vote-button" do
            click_button "Vote"
            expect(page).to have_button("Already voted")
          end

          within "#question-#{question.id}-votes-count" do
            expect(page).to have_content("1 VOTE")
          end
        end
      end

      context "when the question is already voted" do
        before do
          create(:question_vote, question: question, author: user)
          visit_component
        end

        it "is not able to vote it again" do
          within "#question-#{question.id}-vote-button" do
            expect(page).to have_button("Already voted")
            expect(page).to have_no_button("Vote")
          end

          within "#question-#{question.id}-votes-count" do
            expect(page).to have_content("1 VOTE")
          end
        end

        it "is able to undo the vote" do
          within "#question-#{question.id}-vote-button" do
            click_button "Already voted"
            expect(page).to have_button("Vote")
          end

          within "#question-#{question.id}-votes-count" do
            expect(page).to have_content("0 VOTES")
          end
        end
      end

      context "when the component has a vote limit" do
        let(:vote_limit) { 10 }

        let!(:component) do
          create(:question_component,
                 :with_votes_enabled,
                 :with_vote_limit,
                 vote_limit: vote_limit,
                 manifest: manifest,
                 participatory_space: participatory_process)
        end

        describe "vote counter" do
          context "when votes are blocked" do
            let!(:component) do
              create(:question_component,
                     :with_votes_blocked,
                     :with_vote_limit,
                     vote_limit: vote_limit,
                     manifest: manifest,
                     participatory_space: participatory_process)
            end

            it "doesn't show the remaining votes counter" do
              visit_component

              expect(page).to have_css(".voting-rules")
              expect(page).to have_no_css(".remaining-votes-counter")
            end
          end

          context "when votes are enabled" do
            let!(:component) do
              create(:question_component,
                     :with_votes_enabled,
                     :with_vote_limit,
                     vote_limit: vote_limit,
                     manifest: manifest,
                     participatory_space: participatory_process)
            end

            it "shows the remaining votes counter" do
              visit_component

              expect(page).to have_css(".voting-rules")
              expect(page).to have_css(".remaining-votes-counter")
            end
          end
        end

        context "when the question is not voted yet" do
          before do
            visit_component
          end

          it "updates the remaining votes counter" do
            within "#question-#{question.id}-vote-button" do
              click_button "Vote"
              expect(page).to have_button("Already voted")
            end

            expect(page).to have_content("REMAINING\n9\nVOTES")
          end
        end

        context "when the question is not voted yet but the user isn't authorized" do
          before do
            permissions = {
              vote: {
                authorization_handler_name: "dummy_authorization_handler"
              }
            }

            component.update!(permissions: permissions)
            visit_component
          end

          it "shows a modal dialog" do
            within "#question-#{question.id}-vote-button" do
              click_button "Vote"
            end

            expect(page).to have_content("Authorization required")
          end
        end

        context "when the question is already voted" do
          before do
            create(:question_vote, question: question, author: user)
            visit_component
          end

          it "is not able to vote it again" do
            within "#question-#{question.id}-vote-button" do
              expect(page).to have_button("Already voted")
              expect(page).to have_no_button("Vote")
            end
          end

          it "is able to undo the vote" do
            within "#question-#{question.id}-vote-button" do
              click_button "Already voted"
              expect(page).to have_button("Vote")
            end

            within "#question-#{question.id}-votes-count" do
              expect(page).to have_content("0 VOTES")
            end

            expect(page).to have_content("REMAINING\n10\nVOTES")
          end
        end

        context "when the user has reached the votes limit" do
          let(:vote_limit) { 1 }

          before do
            create(:question_vote, question: question, author: user)
            visit_component
          end

          it "is not able to vote other questions" do
            expect(page).to have_css(".button[disabled]", count: 2)
          end

          context "when votes are blocked" do
            let!(:component) do
              create(:question_component,
                     :with_votes_blocked,
                     manifest: manifest,
                     participatory_space: participatory_process)
            end

            it "shows the vote count but not the vote button" do
              within "#question_#{question.id} .card__support" do
                expect(page).to have_content("1 VOTE")
              end

              expect(page).to have_content("VOTING DISABLED")
            end
          end
        end
      end
    end

    context "when the question is rejected" do
      let!(:rejected_question) { create(:question, :rejected, component: component) }

      before do
        component.update!(settings: { question_answering_enabled: true })
      end

      it "cannot be voted" do
        visit_component

        choose "filter_state_rejected"
        page.find_link(rejected_question.title, wait: 30)
        expect(page).to have_no_selector("#question-#{rejected_question.id}-vote-button")

        click_link rejected_question.title
        expect(page).to have_no_selector("#question-#{rejected_question.id}-vote-button")
      end
    end

    context "when questions have a voting limit" do
      let!(:component) do
        create(:question_component,
               :with_votes_enabled,
               :with_threshold_per_question,
               manifest: manifest,
               participatory_space: participatory_process)
      end

      before do
        login_as user, scope: :user
      end

      it "doesn't allow users to vote to a question that's reached the limit" do
        create(:question_vote, question: question)
        visit_component

        question_element = page.find("article", text: question.title)

        within question_element do
          within ".card__support", match: :first do
            expect(page).to have_content("VOTE LIMIT REACHED")
          end
        end
      end

      it "allows users to vote on questions under the limit" do
        visit_component

        question_element = page.find("article", text: question.title)

        within question_element do
          within ".card__support", match: :first do
            click_button "Vote"
            expect(page).to have_content("ALREADY VOTED")
          end
        end
      end
    end

    context "when questions have vote limit but can accumulate more votes" do
      let!(:component) do
        create(:question_component,
               :with_votes_enabled,
               :with_threshold_per_question,
               :with_can_accumulate_supports_beyond_threshold,
               manifest: manifest,
               participatory_space: participatory_process)
      end

      before do
        login_as user, scope: :user
      end

      it "allows users to vote on questions over the limit" do
        create(:question_vote, question: question)
        visit_component

        question_element = page.find("article", text: question.title)

        within question_element do
          within ".card__support", match: :first do
            expect(page).to have_content("1 VOTE")
          end
        end
      end
    end

    context "when questions have a minimum amount of votes" do
      let!(:component) do
        create(:question_component,
               :with_votes_enabled,
               :with_minimum_votes_per_user,
               minimum_votes_per_user: 3,
               manifest: manifest,
               participatory_space: participatory_process)
      end

      before do
        login_as user, scope: :user
      end

      it "doesn't count votes unless the minimum is achieved" do
        visit_component

        question_elements = questions.map do |question|
          page.find("article", text: question.title)
        end

        within question_elements[0] do
          click_button "Vote"
          expect(page).to have_content("ALREADY VOTED")
          expect(page).to have_content("0 VOTES")
        end

        within question_elements[1] do
          click_button "Vote"
          expect(page).to have_content("ALREADY VOTED")
          expect(page).to have_content("0 VOTES")
        end

        within question_elements[2] do
          click_button "Vote"
          expect(page).to have_content("ALREADY VOTED")
          expect(page).to have_content("1 VOTE")
        end

        within question_elements[0] do
          expect(page).to have_content("1 VOTE")
        end

        within question_elements[1] do
          expect(page).to have_content("1 VOTE")
        end
      end
    end

    describe "gamification" do
      before do
        login_as user, scope: :user
      end

      it "gives a point after voting" do
        visit_component

        question_element = page.find("article", text: question.title)

        expect do
          within question_element do
            within ".card__support", match: :first do
              click_button "Vote"
              expect(page).to have_content("1 VOTE")
            end
          end
        end.to change { Decidim::Gamification.status_for(user, :question_votes).score }.by(1)
      end
    end
  end
end
