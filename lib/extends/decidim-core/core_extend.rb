# frozen_string_literal: true

Decidim.module_eval do
  config_accessor :participatory_process_user_roles do
    %w(admin collaborator moderator committee service)
  end
end
