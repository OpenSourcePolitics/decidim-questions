# frozen_string_literal: true

class AddRecipientToQuestions < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_questions_questions, :recipient, :string, default: "", null: true
  end
end
