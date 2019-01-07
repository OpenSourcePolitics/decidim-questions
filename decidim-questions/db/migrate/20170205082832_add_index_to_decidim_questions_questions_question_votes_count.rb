# frozen_string_literal: true

class AddIndexToDecidimQuestionsQuestionsQuestionVotesCount < ActiveRecord::Migration[5.0]
  def change
    add_index :decidim_questions_questions, :question_votes_count
    add_index :decidim_questions_questions, :created_at
    add_index :decidim_questions_questions, :state
  end
end
