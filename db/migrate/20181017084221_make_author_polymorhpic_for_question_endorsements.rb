# frozen_string_literal: true

class MakeAuthorPolymorhpicForQuestionEndorsements < ActiveRecord::Migration[5.2]
  class QuestionEndorsement < ApplicationRecord
    self.table_name = :decidim_questions_question_endorsements
  end

  def change
    remove_index :decidim_questions_question_endorsements, :decidim_author_id

    add_column :decidim_questions_question_endorsements, :decidim_author_type, :string

    reversible do |direction|
      direction.up do
        execute <<~SQL.squish
          UPDATE decidim_questions_question_endorsements
          SET decidim_author_type = 'Decidim::UserBaseEntity'
        SQL
      end
    end

    add_index :decidim_questions_question_endorsements,
              [:decidim_author_id, :decidim_author_type],
              name: "index_decidim_questions_question_endorsements_on_decidim_author"

    change_column_null :decidim_questions_question_endorsements, :decidim_author_id, false
    change_column_null :decidim_questions_question_endorsements, :decidim_author_type, false

    QuestionEndorsement.reset_column_information
  end
end
