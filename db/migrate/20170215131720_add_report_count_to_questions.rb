# frozen_string_literal: true

class AddReportCountToQuestions < ActiveRecord::Migration[5.0]
  def change
    add_column :decidim_questions_questions, :report_count, :integer, default: 0
  end
end
