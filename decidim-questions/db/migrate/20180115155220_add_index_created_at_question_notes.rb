# frozen_string_literal: true

class AddIndexCreatedAtQuestionNotes < ActiveRecord::Migration[5.1]
  def change
    add_index :decidim_questions_question_notes, :created_at
  end
end
