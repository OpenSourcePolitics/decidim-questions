# frozen_string_literal: true

class AddCounterCacheCoauthorshipsToQuestions < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_questions_questions, :coauthorships_count, :integer, null: false, default: 0
    add_index :decidim_questions_questions, :coauthorships_count, name: "idx_decidim_questions_questions_on_question_coauthorships_count"
  end
end
