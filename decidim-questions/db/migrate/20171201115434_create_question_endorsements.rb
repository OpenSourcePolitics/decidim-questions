# frozen_string_literal: true

class CreateQuestionEndorsements < ActiveRecord::Migration[5.1]
  def change
    create_table :decidim_questions_question_endorsements do |t|
      t.references :decidim_question, null: false, index: { name: "decidim_questions_question_endorsement_question" }
      t.references :decidim_author, null: false, index: { name: "decidim_questions_question_endorsement_author" }
      t.references :decidim_user_group, null: true, index: { name: "decidim_questions_question_endorsement_user_group" }

      t.timestamps
    end

    add_index :decidim_questions_question_endorsements, "decidim_question_id, decidim_author_id, (coalesce(decidim_user_group_id,-1))", unique: true, name:
      "decidim_questions_question_endorsmt_question_auth_ugroup_uniq"
  end
end
