# frozen_string_literal: true

class AddCounterCacheVotesToQuestions < ActiveRecord::Migration[5.0]
  def change
    add_column :decidim_questions_questions, :question_votes_count, :integer, null: false, default: 0
  end
end
