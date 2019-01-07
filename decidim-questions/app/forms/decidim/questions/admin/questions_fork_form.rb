# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A common abstract to be used by the Merge and Split questions forms.
      class QuestionsForkForm < Decidim::Form
        mimic :questions_import

        attribute :target_component_id, Integer
        attribute :question_ids, Array

        validates :target_component, :questions, :current_component, presence: true
        validate :same_participatory_space
        validate :mergeable_to_same_component

        def questions
          @questions ||= Decidim::Questions::Question.where(component: current_component, id: question_ids).uniq
        end

        def target_component
          return current_component if clean_target_component_id == current_component.id
          @target_component ||= current_component.siblings.find_by(id: target_component_id)
        end

        def same_component?
          target_component == current_component
        end

        private

        def mergeable_to_same_component
          return true unless same_component?

          public_questions = questions.any? do |question|
            !question.official? || question.votes.any? || question.endorsements.any?
          end

          errors.add(:question_ids, :invalid) if public_questions
        end

        def same_participatory_space
          return if !target_component || !current_component

          errors.add(:target_component, :invalid) if current_component.participatory_space != target_component.participatory_space
        end

        # Private: Returns the id of the target component.
        #
        # We receive this as ["id"] since it's from a select in a form.
        def clean_target_component_id
          target_component_id.first.to_i
        end
      end
    end
  end
end
