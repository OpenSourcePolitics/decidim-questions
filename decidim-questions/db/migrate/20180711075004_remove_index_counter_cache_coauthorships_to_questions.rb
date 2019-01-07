# frozen_string_literal: true

class RemoveIndexCounterCacheCoauthorshipsToQuestions < ActiveRecord::Migration[5.2]
  def change
    remove_index :decidim_questions_questions, name: "idx_decidim_questions_questions_on_question_coauthorships_count"
  end
end
