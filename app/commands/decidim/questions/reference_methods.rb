# frozen_string_literal: true

module Decidim
  module Questions
    module ReferenceMethods
      private

      def reference_need_update?
        need_update = question.state.nil? && %w(evaluating accepted).include?(form.state)
        need_update ||= question.state != form.state && %w(accepted).include?(form.state)
      end

      def manage_custom_reference
        return question.published_at unless reference_need_update?

        prefix = question.component.name[Decidim.config.default_locale.to_s].capitalize[0]
        current_ref = Decidim::Questions::Question.where(state: ['evaluating','accepted']).order(published_at: :desc).first.reference
        next_short_ref = current_ref.split(prefix).last
        next_short_ref = next_short_ref =~ /\A\d+\Z/ ? next_short_ref.to_i + 1 : 0

        default_ref = Decidim.reference_generator.call(question, question.component)

        question.update_column(:reference, default_ref + '-' + prefix + next_short_ref.to_s)
      end
    end
  end
end
