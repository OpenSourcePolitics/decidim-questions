# frozen_string_literal: true

class CreateQuestionReports < ActiveRecord::Migration[5.0]
  def change
    create_table :decidim_questions_question_reports do |t|
      t.references :decidim_question, null: false, index: { name: "decidim_questions_question_result_question" }
      t.references :decidim_user, null: false, index: { name: "decidim_questions_question_result_user" }
      t.string :reason, null: false
      t.text :details

      t.timestamps
    end

    add_index :decidim_questions_question_reports, [:decidim_question_id, :decidim_user_id], unique: true, name: "decidim_questions_question_report_question_user_unique"
  end
end
