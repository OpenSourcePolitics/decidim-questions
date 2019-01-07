# frozen_string_literal: true

class CreateDecidimQuestionNotes < ActiveRecord::Migration[5.1]
  def change
    create_table :decidim_questions_question_notes do |t|
      t.references :decidim_question, null: false, index: { name: "decidim_questions_question_note_question" }
      t.references :decidim_author, null: false, index: { name: "decidim_questions_question_note_author" }
      t.text :body, null: false

      t.timestamps
    end

    add_column :decidim_questions_questions, :question_notes_count, :integer, null: false, default: 0
  end
end
