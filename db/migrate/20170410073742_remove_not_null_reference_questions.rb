# frozen_string_literal: true

class RemoveNotNullReferenceQuestions < ActiveRecord::Migration[5.0]
  def change
    change_column_null :decidim_questions_questions, :reference, true
  end
end
