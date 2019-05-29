# frozen_string_literal: true

class AddRecipientIdsToQuestions < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_questions_questions, :recipient_ids, :integer, array: true, default: [], null: false
  end
end
