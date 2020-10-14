# frozen_string_literal: true

module Decidim
  module Questions
    module ReferenceMethods
      private

      def reference_needs_update?
        !question.emendation? && !question.short_ref.match?(/\A\D\d+\Z/) && updatable_state?
      end

      def manage_custom_reference
        return unless reference_needs_update?

        question.update_column(:reference, custom_reference(question))
      end

      def custom_reference(resource)
        return unless resource.class.to_s == "Decidim::Questions::Question"

        prefix = resource.component.name[Decidim.config.default_locale.to_s].capitalize[0]

        references = Decidim::Questions::Question.where("reference ~* ?", prefix + '\d+$')
                                                 .where(component: resource.component, state: %w(evaluating pending accepted))
                                                 .pluck(:reference)

        references.map! do |reference|
          ref = reference.split(prefix).last
          /\A\d+\Z/.match?(ref) ? ref.to_i : 0
        end

        references.sort!

        current_index = references.empty? ? 0 : references.last
        current_index += 1
        default_ref = Decidim.reference_generator.call(resource, resource.component)

        default_ref + "-" + prefix + current_index.to_s
      end

      def updatable_state?
        state_changed_to_evaluating_or_accepted? || existing_state_changed_to_accepted?
      end

      def state_changed_to_evaluating_or_accepted?
        question.state.nil? && (evaluating_state? || accepted_state?)
      end

      def existing_state_changed_to_accepted?
        question.state != form.state && accepted_state?
      end

      def evaluating_state?
        %w(evaluating).include?(form.state)
      end

      def accepted_state?
        %w(accepted).include?(form.state)
      end
    end
  end
end
