# frozen_string_literal: true

class RemoveAuthorshipsFromQuestions < ActiveRecord::Migration[5.1]
  def change
    remove_column :decidim_questions_questions, :decidim_author_id, :integer
    remove_column :decidim_questions_questions, :decidim_user_group_id, :integer
  end
end
