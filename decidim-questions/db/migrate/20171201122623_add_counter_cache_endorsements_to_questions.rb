# frozen_string_literal: true

class AddCounterCacheEndorsementsToQuestions < ActiveRecord::Migration[5.1]
  def change
    add_column :decidim_questions_questions, :question_endorsements_count, :integer, null: false, default: 0
    add_index :decidim_questions_questions, :question_endorsements_count, name: "idx_decidim_questions_questions_on_question_endorsemnts_count"
  end
end
