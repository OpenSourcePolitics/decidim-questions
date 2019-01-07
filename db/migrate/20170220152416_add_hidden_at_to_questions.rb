# frozen_string_literal: true

class AddHiddenAtToQuestions < ActiveRecord::Migration[5.0]
  def change
    add_column :decidim_questions_questions, :hidden_at, :datetime
  end
end
