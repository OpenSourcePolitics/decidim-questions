require 'extends/decidim-core/core_extend.rb'
require 'extends/decidim-core/helpers/decidim/application_helper_extend.rb'
require 'extends/decidim-admin/helpers/decidim/admin/application_helper_extend.rb'

ActiveSupport.on_load(:active_record) {

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
      require 'extends/decidim-participatory_processes/models/decidim/participatory_process_extend.rb'
    end
  end
  
}

require 'extends/decidim-participatory_processes/controllers/decidim/participatory_processes/admin/participatory_processes_controller_extend.rb'
require 'extends/decidim-core/commands/decidim/amendable/create_extend.rb'
require 'extends/decidim-core/commands/decidim/amendable/promote_extend.rb'
require 'extends/decidim-core/helpers/decidim/cells_helper_extend.rb'
require 'extends/decidim-core/cells/decidim/author_cell_extend.rb'
