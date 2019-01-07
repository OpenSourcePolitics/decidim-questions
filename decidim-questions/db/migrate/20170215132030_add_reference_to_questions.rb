# frozen_string_literal: true

class AddReferenceToQuestions < ActiveRecord::Migration[5.0]
  class Question < ApplicationRecord
    self.table_name = :decidim_questions_questions
  end

  def change
    add_column :decidim_questions_questions, :reference, :string
    Question.find_each(&:save)
    change_column_null :decidim_questions_questions, :reference, false
  end
end
