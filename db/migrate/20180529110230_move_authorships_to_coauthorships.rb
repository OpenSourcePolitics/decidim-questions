# frozen_string_literal: true

class MoveAuthorshipsToCoauthorships < ActiveRecord::Migration[5.1]
  class Question < ApplicationRecord
    self.table_name = :decidim_questions_questions
  end
  class Coauthorship < ApplicationRecord
    self.table_name = :decidim_coauthorships
  end

  def change
    questions = Question.all

    questions.each do |question|
      author_id = question.attributes["decidim_author_id"]
      user_group_id = question.attributes["decidim_user_group_id"]

      next if author_id.nil?

      Coauthorship.create!(
        coauthorable_id: question.id,
        coauthorable_type: "Decidim::Questions::Question",
        decidim_author_id: author_id,
        decidim_user_group_id: user_group_id
      )
    end
  end
end
