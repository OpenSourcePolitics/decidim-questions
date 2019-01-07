# frozen_string_literal: true

class FixNilThresholdPerQuestion < ActiveRecord::Migration[5.1]
  class Component < ApplicationRecord
    self.table_name = :decidim_components
  end

  def change
    question_components = Component.where(manifest_name: "questions")

    question_components.each do |component|
      settings = component.attributes["settings"]
      settings["global"]["threshold_per_question"] ||= 0
      component.settings = settings
      component.save
    end
  end
end
