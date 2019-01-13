# frozen_string_literal: true

namespace :decidim do
  desc "Install migrations from Decidim to the app."
  task upgrade: [:choose_target_plugins, :"railties:install:migrations"]

  desc "Setup environment so that only decidim migrations are installed."
  task :choose_target_plugins do
    ENV["FROM"] = %w(
      decidim_participatory_processes
      decidim
      decidim_system
      decidim_assemblies
      decidim_conferences
      decidim_consultations
      decidim_admin
      decidim_accountability
      decidim_blogs
      decidim_budgets
      decidim_comments
      decidim_debates
      decidim_forms
      decidim_initiatives
      decidim_meetings
      decidim_pages
      decidim_proposals
      decidim_questions
      decidim_sortitions
      decidim_surveys
      decidim_verifications
    ).join(",")
  end
end
