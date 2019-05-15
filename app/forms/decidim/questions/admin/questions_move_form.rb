# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A form object to be used when admin users wants to merge two or more
      # questions into a new one to another question component in the same space.
      class QuestionsMoveForm < QuestionsForkForm
        validates :questions, length: { minimum: 1 }
        attribute :target_component_id, Integer

        validates :target_component, :questions, :current_component, presence: true
        validate :same_participatory_space

        def questions
          @questions ||= Decidim::Questions::Question.where(component: current_component, id: question_ids).uniq
        end

        def target_component
          return current_component if clean_target_component_id == current_component.id
          @target_component ||= current_component.siblings.find_by(id: target_component_id)
        end
      end
    end
  end
end
