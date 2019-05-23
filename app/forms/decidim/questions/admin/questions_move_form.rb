# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A form object to be used when admin users wants to merge two or more
      # questions into a new one to another question component in the same space.
      class QuestionsMoveForm < Decidim::Form
        validates :questions, length: { minimum: 1 }
        attribute :target_component_id, Integer
        attribute :question_ids, Array

        validates :target_component, :questions, :current_component, presence: true
        validate :same_participatory_space

        def questions
          @questions ||= Decidim::Questions::Question.where(component: current_component, id: question_ids).uniq
        end

        def target_component
          return current_component if target_component_id.first.to_i == current_component.id
          @target_component ||= current_component.siblings.find_by(id: target_component_id)
        end

        private

        def same_participatory_space
          return if !target_component || !current_component

          errors.add(:target_component, :invalid) if current_component.participatory_space != target_component.participatory_space
        end
      end
    end
  end
end
