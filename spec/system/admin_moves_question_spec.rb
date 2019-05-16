# frozen_string_literal: true

require "spec_helper"

describe "Admin moves questions", type: :system do
  let(:manifest_name) { "questions" }
  let(:organization) { participatory_space.organization }
  let(:participatory_space) { component.participatory_space }
  let!(:user) { create :user, :admin, :confirmed, organization: organization }
  let!(:questions) { create_list :question, 3, :official, component: component }
  let!(:target_component) { create(:question_component, participatory_space: component.participatory_space) }

  include_context "when managing a component as an admin"

  describe "moving several questions" do
    it "they can be moved to another component" do
      visit_component_admin

      questions_to_move = questions[0..1]

      questions_to_move.each do |question|
        within "tr[data-id='#{question.id}']" do
          page.find('input[type="checkbox"]').click
        end
      end

      find("#js-bulk-actions-button").click
      find('button[data-action="move-questions"]').click
      page.find("#js-form-move-questions select").find("option", text: target_component.name["en"]).select_option
      page.click_button("Move")

      questions_to_move.each do |question|
        expect(page).to have_no_content(question.title)
        expect(question.reload.component).to eq(target_component)
      end
    end
  end
end
