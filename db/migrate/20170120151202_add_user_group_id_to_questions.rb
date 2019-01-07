# frozen_string_literal: true

class AddUserGroupIdToQuestions < ActiveRecord::Migration[5.0]
  def change
    add_column :decidim_questions_questions, :decidim_user_group_id, :integer, index: true
  end
end
