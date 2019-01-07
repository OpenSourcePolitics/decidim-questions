# frozen_string_literal: true

class AddOrganizationAsAuthor < ActiveRecord::Migration[5.2]
  def change
    official_questions = Decidim::Questions::Question.find_each.select do |question|
      question.coauthorships.count.zero?
    end

    official_questions.each do |question|
      question.add_coauthor(question.organization)
    end
  end
end
