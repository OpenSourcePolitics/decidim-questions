# frozen_string_literal: true

require "spec_helper"

describe "Admin manages questions", type: :system do
  let(:manifest_name) { "questions" }
  let!(:question) { create :question, component: current_component }
  let!(:reportables) { create_list(:question, 3, component: current_component) }
  let(:participatory_space_path) do
    decidim_admin_participatory_processes.edit_participatory_process_path(participatory_process)
  end

  include_context "when managing a component as an admin"

  it_behaves_like "manage questions"
  it_behaves_like "manage moderations"
  it_behaves_like "export questions"
  it_behaves_like "manage announcements"
  it_behaves_like "manage questions help texts"
  it_behaves_like "manage question wizard steps help texts"
  it_behaves_like "when managing questions category as an admin"
  it_behaves_like "import questions"
  it_behaves_like "manage questions permissions"
  it_behaves_like "merge questions"
  it_behaves_like "split questions"
end
