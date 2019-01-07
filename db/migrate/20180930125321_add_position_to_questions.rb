# frozen_string_literal: true

class AddPositionToQuestions < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_questions_questions, :position, :integer
  end
end
