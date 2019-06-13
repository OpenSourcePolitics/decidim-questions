# frozen_string_literal: true

require "extends/decidim-core/core_extend.rb"
require "extends/decidim-core/helpers/decidim/application_helper_extend.rb"
require "extends/decidim-admin/helpers/decidim/admin/application_helper_extend.rb"

ActiveSupport.on_load(:active_record) do
  def database_exists?
    ActiveRecord::Base.connection
  rescue ActiveRecord::NoDatabaseError
    false
  else
    true
  end

  # Models needs to be loaded AFTER DB init because of legacy Migrations
  if database_exists?
    if ActiveRecord::Base.connection.table_exists?(:decidim_participatory_processes)
      require "extends/decidim-participatory_processes/models/decidim/participatory_process_extend.rb"
    end
  end
end

require "extends/decidim-admin/controllers/decidim/participatory_processes/admin/moderations_controller_extend.rb"
require "extends/decidim-admin/controllers/decidim/participatory_processes/admin/upstream_moderations_controller_extend.rb"
require "extends/decidim-participatory_processes/controllers/decidim/participatory_processes/admin/participatory_processes_controller_extend.rb"
require "extends/decidim-participatory_processes/controllers/decidim/participatory_processes/admin/participatory_processes_steps_controller_extend.rb"
require "extends/decidim-participatory_processes/controllers/decidim/participatory_processes/admin/participatory_processes_categories_controller_extend.rb"
require "extends/decidim-participatory_processes/controllers/decidim/participatory_processes/admin/participatory_processes_components_controller_extend.rb"
require "extends/decidim-participatory_processes/controllers/decidim/participatory_processes/admin/participatory_processes_attachments_controller_extend.rb"
require "extends/decidim-participatory_processes/controllers/decidim/participatory_processes/admin/participatory_processes_attachment_collections_controller_extend.rb"
require "extends/decidim-participatory_processes/controllers/decidim/participatory_processes/admin/participatory_processes_user_roles_controller_extend.rb"
require "extends/decidim-core/commands/decidim/amendable/create_extend.rb"
require "extends/decidim-core/commands/decidim/amendable/promote_extend.rb"
require "extends/decidim-core/helpers/decidim/cells_helper_extend.rb"
require "extends/decidim-core/cells/decidim/author_cell_extend.rb"
