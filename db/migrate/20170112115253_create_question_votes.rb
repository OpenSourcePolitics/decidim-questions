# frozen_string_literal: true

class CreateQuestionVotes < ActiveRecord::Migration[5.0]
  def change
    create_table :decidim_questions_question_votes do |t|
      t.references :decidim_question, null: false, index: { name: "decidim_questions_question_vote_question" }
      t.references :decidim_author, null: false, index: { name: "decidim_questions_question_vote_author" }

      t.timestamps
    end

    add_index :decidim_questions_question_votes, [:decidim_question_id, :decidim_author_id], unique: true, name: "decidim_questions_question_vote_question_author_unique"
  end
end
