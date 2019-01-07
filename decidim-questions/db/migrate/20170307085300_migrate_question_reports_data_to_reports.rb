# frozen_string_literal: true

class MigrateQuestionReportsDataToReports < ActiveRecord::Migration[5.0]
  class Decidim::Questions::QuestionReport < ApplicationRecord
    belongs_to :user, foreign_key: "decidim_user_id", class_name: "Decidim::User"
    belongs_to :question, foreign_key: "decidim_question_id", class_name: "Decidim::Questions::Question"
  end

  def change
    Decidim::Questions::QuestionReport.find_each do |question_report|
      moderation = Decidim::Moderation.find_or_create_by!(reportable: question_report.question,
                                                          participatory_process: question_report.question.feature.participatory_space)
      Decidim::Report.create!(moderation: moderation,
                              user: question_report.user,
                              reason: question_report.reason,
                              details: question_report.details)
      moderation.update!(report_count: moderation.report_count + 1)
    end

    drop_table :decidim_questions_question_reports
    remove_column :decidim_questions_questions, :report_count
    remove_column :decidim_questions_questions, :hidden_at
  end
end
