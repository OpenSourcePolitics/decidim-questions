# frozen_string_literal: true

class AddParticipatoryTextLevelToQuestions < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_questions_questions, :participatory_text_level, :string
  end
end
