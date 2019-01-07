# frozen_string_literal: true

class AddGeolocalizationFieldsToQuestions < ActiveRecord::Migration[5.0]
  def change
    add_column :decidim_questions_questions, :address, :text
    add_column :decidim_questions_questions, :latitude, :float
    add_column :decidim_questions_questions, :longitude, :float
  end
end
