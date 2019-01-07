# frozen_string_literal: true

class AddAnswersToQuestions < ActiveRecord::Migration[5.0]
  def change
    add_column :decidim_questions_questions, :state, :string, index: true
    add_column :decidim_questions_questions, :answered_at, :datetime, index: true
    add_column :decidim_questions_questions, :answer, :jsonb
  end
end
