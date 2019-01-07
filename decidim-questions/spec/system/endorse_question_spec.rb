# frozen_string_literal: true

require "spec_helper"

describe "Endorse Question", type: :system do
  include_context "with a component"
  let(:manifest_name) { "questions" }

  let!(:questions) { create_list(:question, 3, component: component) }
  let!(:question) { Decidim::Questions::Question.find_by(component: component) }
  let!(:user) { create :user, :confirmed, organization: organization }

  def expect_page_not_to_include_endorsements
    expect(page).to have_no_button("Endorse")
    expect(page).to have_no_css("#question-#{question.id}-endorsements-count")
  end

  def visit_question
    visit_component
    click_link question.title
  end

  context "when endorsements are not enabled" do
    let!(:component) do
      create(:question_component,
             :with_votes_enabled, :with_endorsements_disabled,
             manifest: manifest,
             participatory_space: participatory_process)
    end

    context "when the user is not logged in" do
      it "doesn't show the endorse question button and counts" do
        visit_question
        expect_page_not_to_include_endorsements
      end
    end

    context "when the user is logged in" do
      before do
        login_as user, scope: :user
      end

      it "doesn't show the endorse question button and counts" do
        visit_question
        expect_page_not_to_include_endorsements
      end
    end
  end

  context "when endorsements are blocked" do
    let!(:component) do
      create(:question_component,
             :with_votes_enabled, :with_endorsements_blocked,
             manifest: manifest,
             participatory_space: participatory_process)
    end

    it "shows the endorsements count and the endorse button is disabled" do
      visit_question
      expect(page).to have_css(".buttons__row span[disabled]")
    end
  end

  context "when endorsements are enabled" do
    context "when the user is not logged in" do
      before do
        visit_component
        click_link question.title
      end

      it "is given the option to sign in" do
        visit_question
        within ".buttons__row", match: :first do
          click_button "Endorse"
        end

        expect(page).to have_css("#loginModal", visible: true)
      end
    end

    context "when the user is logged in" do
      before do
        endorsement
        login_as user, scope: :user
      end

      context "when the question is not endorsed yet" do
        let(:endorsement) {}

        it "is able to endorse the question" do
          visit_question
          within ".buttons__row" do
            click_button "Endorse"
            expect(page).to have_button("Endorsed")
          end

          within "#question-#{question.id}-endorsements-count" do
            expect(page).to have_content("1")
          end
        end
      end

      context "when the question is already endorsed" do
        let(:endorsement) { create(:question_endorsement, question: question, author: user) }

        it "is not able to endorse it again" do
          visit_question
          within ".buttons__row" do
            expect(page).to have_button("Endorsed")
            expect(page).to have_no_button("Endorse ")
          end

          within "#question-#{question.id}-endorsements-count" do
            expect(page).to have_content("1")
          end
        end

        it "is able to undo the endorsement" do
          visit_question
          within ".buttons__row" do
            click_button "Endorsed"
            expect(page).to have_button("Endorse")
          end

          within "#question-#{question.id}-endorsements-count" do
            expect(page).to have_content("0")
          end
        end
      end

      context "when verification is required" do
        let(:endorsement) {}
        let(:permissions) do
          { endorse: { authorization_handler_name: "dummy_authorization_handler" } }
        end

        before do
          organization.available_authorizations = ["dummy_authorization_handler"]
          organization.save!
          component.update(permissions: permissions)
        end

        context "when user is NOT verified" do
          it "is NOT able to endorse" do
            visit_question
            within ".buttons__row", match: :first do
              click_button "Endorse"
            end
            expect(page).to have_css("#authorizationModal", visible: true)
          end
        end

        context "when user IS verified" do
          before do
            handler_params = { user: user }
            handler_name = "dummy_authorization_handler"
            handler = Decidim::AuthorizationHandler.handler_for(handler_name, handler_params)

            Decidim::Authorization.create_or_update_from(handler)
          end

          it "IS able to endorse" do
            visit_question
            within ".buttons__row", match: :first do
              click_button "Endorse"
            end
            expect(page).to have_button("Endorsed")
          end
        end
      end
    end
  end
end
