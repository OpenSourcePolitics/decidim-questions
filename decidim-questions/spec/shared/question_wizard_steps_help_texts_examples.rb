# frozen_string_literal: true

shared_examples "manage question wizard steps help texts" do
  before do
    current_component.update!(
      step_settings: {
        current_component.participatory_space.active_step.id => {
          creation_enabled: true
        }
      }
    )
  end

  let!(:question) { create(:question, component: current_component) }
  let!(:question_similar) { create(:question, component: current_component, title: "This question is to ensure a similar exists") }
  let!(:question_draft) { create(:question, :draft, component: current_component, title: "This question has a similar") }

  it "customize the help text for step 1 of the question wizard" do
    visit edit_component_path(current_component)

    fill_in_i18n_editor(
      :component_settings_question_wizard_step_1_help_text,
      "#global-settings-question_wizard_step_1_help_text-tabs",
      en: "This is the first step of the Question creation wizard.",
      es: "Este es el primer paso del asistente de creación de propuestas.",
      ca: "Aquest és el primer pas de l'assistent de creació de la proposta."
    )

    click_button "Update"

    visit new_question_path(current_component)
    within ".question_wizard_help_text" do
      expect(page).to have_content("This is the first step of the Question creation wizard.")
    end
  end

  it "customize the help text for step 2 of the question wizard" do
    visit edit_component_path(current_component)

    fill_in_i18n_editor(
      :component_settings_question_wizard_step_2_help_text,
      "#global-settings-question_wizard_step_2_help_text-tabs",
      en: "This is the second step of the Question creation wizard.",
      es: "Este es el segundo paso del asistente de creación de propuestas.",
      ca: "Aquest és el segon pas de l'assistent de creació de la proposta."
    )

    click_button "Update"

    create(:question, title: "More sidewalks and less roads", body: "Cities need more people, not more cars", component: component)
    create(:question, title: "More trees and parks", body: "Green is always better", component: component)
    visit_component
    click_link "New question"
    within ".new_question" do
      fill_in :question_title, with: "More sidewalks and less roads"
      fill_in :question_body, with: "Cities need more people, not more cars"

      find("*[type=submit]").click
    end

    within ".question_wizard_help_text" do
      expect(page).to have_content("This is the second step of the Question creation wizard.")
    end
  end

  it "customize the help text for step 3 of the question wizard" do
    visit edit_component_path(current_component)

    fill_in_i18n_editor(
      :component_settings_question_wizard_step_3_help_text,
      "#global-settings-question_wizard_step_3_help_text-tabs",
      en: "This is the third step of the Question creation wizard.",
      es: "Este es el tercer paso del asistente de creación de propuestas.",
      ca: "Aquest és el tercer pas de l'assistent de creació de la proposta."
    )

    click_button "Update"

    visit_component
    click_link "New question"
    within ".new_question" do
      fill_in :question_title, with: "More sidewalks and less roads"
      fill_in :question_body, with: "Cities need more people, not more cars"

      find("*[type=submit]").click
    end

    within ".question_wizard_help_text" do
      expect(page).to have_content("This is the third step of the Question creation wizard.")
    end
  end

  it "customize the help text for step 4 of the question wizard" do
    visit edit_component_path(current_component)

    fill_in_i18n_editor(
      :component_settings_question_wizard_step_4_help_text,
      "#global-settings-question_wizard_step_4_help_text-tabs",
      en: "This is the fourth step of the Question creation wizard.",
      es: "Este es el cuarto paso del asistente de creación de propuestas.",
      ca: "Aquest és el quart pas de l'assistent de creació de la proposta."
    )

    click_button "Update"

    visit preview_question_path(current_component, question_draft)
    within ".question_wizard_help_text" do
      expect(page).to have_content("This is the fourth step of the Question creation wizard.")
    end
  end

  private

  def new_question_path(current_component)
    Decidim::EngineRouter.main_proxy(current_component).new_question_path(current_component.id)
  end

  def complete_question_path(current_component, question)
    Decidim::EngineRouter.main_proxy(current_component).complete_question_path(question)
  end

  def preview_question_path(current_component, question)
    Decidim::EngineRouter.main_proxy(current_component).question_path(question) + "/preview"
  end
end
