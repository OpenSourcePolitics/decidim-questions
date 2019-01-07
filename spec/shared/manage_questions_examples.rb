# frozen_string_literal: true

shared_examples "manage questions" do
  let(:address) { "Carrer Pare Llaurador 113, baixos, 08224 Terrassa" }
  let(:latitude) { 40.1234 }
  let(:longitude) { 2.1234 }
  let(:participatory_process) { create(:participatory_process, :with_steps, organization: organization, scope: participatory_process_scope) }
  let(:participatory_process_scope) { nil }

  before do
    stub_geocoding(address, [latitude, longitude])
  end

  context "when previewing questions" do
    it "allows the user to preview the question" do
      within find("tr", text: question.title) do
        klass = "action-icon--preview"
        href = resource_locator(question).path
        target = "blank"

        expect(page).to have_selector(
          :xpath,
          "//a[contains(@class,'#{klass}')][@href='#{href}'][@target='#{target}']"
        )
      end
    end
  end

  describe "creation" do
    context "when official_questions setting is enabled" do
      before do
        current_component.update!(settings: { official_questions_enabled: true })
      end

      context "when creation is enabled" do
        before do
          current_component.update!(
            step_settings: {
              current_component.participatory_space.active_step.id => {
                creation_enabled: true
              }
            }
          )

          visit_component_admin
        end

        context "when process is not related to any scope" do
          it "can be related to a scope" do
            click_link "New question"

            within "form" do
              expect(page).to have_content(/Scope/i)
            end
          end

          it "creates a new question", :slow do
            click_link "New question"

            within ".new_question" do
              fill_in :question_title, with: "Make decidim great again"
              fill_in :question_body, with: "Decidim is great but it can be better"
              select translated(category.name), from: :question_category_id
              scope_pick select_data_picker(:question_scope_id), scope
              find("*[type=submit]").click
            end

            expect(page).to have_admin_callout("successfully")

            within "table" do
              question = Decidim::Questions::Question.last

              expect(page).to have_content("Make decidim great again")
              expect(question.body).to eq("Decidim is great but it can be better")
              expect(question.category).to eq(category)
              expect(question.scope).to eq(scope)
            end
          end
        end

        context "when process is related to a scope" do
          let(:participatory_process_scope) { scope }

          it "cannot be related to a scope, because it has no children" do
            click_link "New question"

            within "form" do
              expect(page).to have_no_content(/Scope/i)
            end
          end

          it "creates a new question related to the process scope" do
            click_link "New question"

            within ".new_question" do
              fill_in :question_title, with: "Make decidim great again"
              fill_in :question_body, with: "Decidim is great but it can be better"
              select category.name["en"], from: :question_category_id
              find("*[type=submit]").click
            end

            expect(page).to have_admin_callout("successfully")

            within "table" do
              question = Decidim::Questions::Question.last

              expect(page).to have_content("Make decidim great again")
              expect(question.body).to eq("Decidim is great but it can be better")
              expect(question.category).to eq(category)
              expect(question.scope).to eq(scope)
            end
          end

          context "when the process scope has a child scope" do
            let!(:child_scope) { create :scope, parent: scope }

            it "can be related to a scope" do
              click_link "New question"

              within "form" do
                expect(page).to have_content(/Scope/i)
              end
            end

            it "creates a new question related to a process scope child" do
              click_link "New question"

              within ".new_question" do
                fill_in :question_title, with: "Make decidim great again"
                fill_in :question_body, with: "Decidim is great but it can be better"
                select category.name["en"], from: :question_category_id
                scope_repick select_data_picker(:question_scope_id), scope, child_scope
                find("*[type=submit]").click
              end

              expect(page).to have_admin_callout("successfully")

              within "table" do
                question = Decidim::Questions::Question.last

                expect(page).to have_content("Make decidim great again")
                expect(question.body).to eq("Decidim is great but it can be better")
                expect(question.category).to eq(category)
                expect(question.scope).to eq(child_scope)
              end
            end
          end

          context "when geocoding is enabled" do
            before do
              current_component.update!(settings: { geocoding_enabled: true })
            end

            it "creates a new question related to the process scope" do
              click_link "New question"

              within ".new_question" do
                fill_in :question_title, with: "Make decidim great again"
                fill_in :question_body, with: "Decidim is great but it can be better"
                fill_in :question_address, with: address
                select category.name["en"], from: :question_category_id
                find("*[type=submit]").click
              end

              expect(page).to have_admin_callout("successfully")

              within "table" do
                question = Decidim::Questions::Question.last

                expect(page).to have_content("Make decidim great again")
                expect(question.body).to eq("Decidim is great but it can be better")
                expect(question.category).to eq(category)
                expect(question.scope).to eq(scope)
              end
            end
          end
        end

        context "when attachments are allowed", processing_uploads_for: Decidim::AttachmentUploader do
          before do
            current_component.update!(settings: { attachments_allowed: true })
          end

          it "creates a new question with attachments" do
            click_link "New question"

            within ".new_question" do
              fill_in :question_title, with: "Question with attachments"
              fill_in :question_body, with: "This is my question and I want to upload attachments."
              fill_in :question_attachment_title, with: "My attachment"
              attach_file :question_attachment_file, Decidim::Dev.asset("city.jpeg")
              find("*[type=submit]").click
            end

            expect(page).to have_admin_callout("successfully")

            visit resource_locator(Decidim::Questions::Question.last).path
            expect(page).to have_selector("img[src*=\"city.jpeg\"]", count: 1)
          end
        end

        context "when questions comes from a meeting" do
          let!(:meeting_component) { create(:meeting_component, participatory_space: participatory_process) }
          let!(:meetings) { create_list(:meeting, 3, component: meeting_component) }

          it "creates a new question with meeting as author" do
            click_link "New question"

            within ".new_question" do
              fill_in :question_title, with: "Question with meeting as author"
              fill_in :question_body, with: "Question body of meeting as author"
              execute_script("$('#question_created_in_meeting').change()")
              find(:css, "#question_created_in_meeting").set(true)
              select translated(meetings.first.title), from: :question_meeting_id
              select category.name["en"], from: :question_category_id
              find("*[type=submit]").click
            end

            expect(page).to have_admin_callout("successfully")

            within "table" do
              question = Decidim::Questions::Question.last

              expect(page).to have_content("Question with meeting as author")
              expect(question.body).to eq("Question body of meeting as author")
              expect(question.category).to eq(category)
            end
          end
        end
      end

      context "when creation is not enabled" do
        before do
          current_component.update!(
            step_settings: {
              current_component.participatory_space.active_step.id => {
                creation_enabled: false
              }
            }
          )
        end

        it "cannot create a new question from the main site" do
          visit_component
          expect(page).to have_no_button("New Question")
        end

        it "cannot create a new question from the admin site" do
          visit_component_admin
          expect(page).to have_no_link(/New/)
        end
      end
    end

    context "when official_questions setting is disabled" do
      before do
        current_component.update!(settings: { official_questions_enabled: false })
      end

      it "cannot create a new question from the main site" do
        visit_component
        expect(page).to have_no_button("New Question")
      end

      it "cannot create a new question from the admin site" do
        visit_component_admin
        expect(page).to have_no_link(/New/)
      end
    end
  end

  context "when the question_answering component setting is enabled" do
    before do
      current_component.update!(settings: { question_answering_enabled: true })
    end

    context "when the question_answering step setting is enabled" do
      before do
        current_component.update!(
          step_settings: {
            current_component.participatory_space.active_step.id => {
              question_answering_enabled: true
            }
          }
        )
      end

      it "can reject a question" do
        go_to_edit_answer(question)

        within ".edit_question_answer" do
          fill_in_i18n_editor(
            :question_answer_answer,
            "#question_answer-answer-tabs",
            en: "The question doesn't make any sense",
            es: "La propuesta no tiene sentido",
            ca: "La proposta no te sentit"
          )
          choose "Rejected"
          click_button "Answer"
        end

        expect(page).to have_admin_callout("Question successfully answered")

        within find("tr", text: question.title) do
          expect(page).to have_content("Rejected")
        end
      end

      it "can accept a question" do
        go_to_edit_answer(question)

        within ".edit_question_answer" do
          choose "Accepted"
          click_button "Answer"
        end

        expect(page).to have_admin_callout("Question successfully answered")

        within find("tr", text: question.title) do
          expect(page).to have_content("Accepted")
        end
      end

      it "can mark a question as evaluating" do
        go_to_edit_answer(question)

        within ".edit_question_answer" do
          choose "Evaluating"
          click_button "Answer"
        end

        expect(page).to have_admin_callout("Question successfully answered")

        within find("tr", text: question.title) do
          expect(page).to have_content("Evaluating")
        end
      end

      it "can edit a question answer" do
        question.update!(
          state: "rejected",
          answer: {
            "en" => "I don't like it"
          },
          answered_at: Time.current
        )

        visit_component_admin

        within find("tr", text: question.title) do
          expect(page).to have_content("Rejected")
        end

        go_to_edit_answer(question)

        within ".edit_question_answer" do
          choose "Accepted"
          click_button "Answer"
        end

        expect(page).to have_admin_callout("Question successfully answered")

        within find("tr", text: question.title) do
          expect(page).to have_content("Accepted")
        end
      end
    end

    context "when the question_answering step setting is disabled" do
      before do
        current_component.update!(
          step_settings: {
            current_component.participatory_space.active_step.id => {
              question_answering_enabled: false
            }
          }
        )
      end

      it "cannot answer a question" do
        visit current_path

        within find("tr", text: question.title) do
          expect(page).to have_no_link("Answer")
        end
      end
    end

    context "when the question is an emendation" do
      let!(:amendable) { create(:question, component: current_component) }
      let!(:emendation) { create(:question, component: current_component) }
      let!(:amendment) { create :amendment, amender: emendation.creator_author, amendable: amendable, emendation: emendation, state: "evaluating" }

      it "cannot answer a question" do
        visit_component_admin
        within find("tr", text: I18n.t("decidim/amendment", scope: "activerecord.models", count: 1)) do
          expect(page).to have_no_link("Answer")
        end
      end
    end
  end

  context "when the question_answering component setting is disabled" do
    before do
      current_component.update!(settings: { question_answering_enabled: false })
    end

    it "cannot answer a question" do
      visit current_path

      within find("tr", text: question.title) do
        expect(page).to have_no_link("Answer")
      end
    end
  end

  context "when the votes_enabled component setting is disabled" do
    before do
      current_component.update!(
        step_settings: {
          component.participatory_space.active_step.id => {
            votes_enabled: false
          }
        }
      )
    end

    it "doesn't show the votes column" do
      visit current_path

      within "thead" do
        expect(page).not_to have_content("VOTES")
      end
    end
  end

  context "when the votes_enabled component setting is enabled" do
    before do
      current_component.update!(
        step_settings: {
          component.participatory_space.active_step.id => {
            votes_enabled: true
          }
        }
      )
    end

    it "shows the votes column" do
      visit current_path

      within "thead" do
        expect(page).to have_content("VOTES")
      end
    end
  end

  def go_to_edit_answer(question)
    within find("tr", text: question.title) do
      click_link "Answer"
    end

    expect(page).to have_selector(".edit_question_answer")
  end
end
