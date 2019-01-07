# frozen_string_literal: true

class AddCreatedInMeeting < ActiveRecord::Migration[5.2]
  def change
    add_column :decidim_questions_questions, :created_in_meeting, :boolean, default: false
  end
end
