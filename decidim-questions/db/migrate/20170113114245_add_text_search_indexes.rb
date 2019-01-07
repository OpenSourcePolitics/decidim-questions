# frozen_string_literal: true

class AddTextSearchIndexes < ActiveRecord::Migration[5.0]
  def change
    add_index :decidim_questions_questions, :title, name: "decidim_questions_question_title_search"
    add_index :decidim_questions_questions, :body, name: "decidim_questions_question_body_search"
  end
end
