# frozen_string_literal: true

class AddPublishedAtToQuestions < ActiveRecord::Migration[5.1]
  def up
    add_column :decidim_questions_questions, :published_at, :datetime, index: true
    # rubocop:disable Rails/SkipsModelValidations
    Decidim::Questions::Question.update_all("published_at = updated_at")
    # rubocop:enable Rails/SkipsModelValidations
  end

  def down
    remove_column :decidim_questions_questions, :published_at
  end
end
