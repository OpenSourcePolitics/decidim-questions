# frozen_string_literal: true

module Decidim
  module Questions
    # A form object to be used when public users want to create a question.
    class QuestionWizardCreateStepForm < Decidim::Form
      mimic :question

      attribute :title, String
      attribute :body, String
      attribute :user_group_id, Integer

      validates :title, :body, presence: true, etiquette: true
      validates :title, length: { maximum: 150 }

      validate :question_length
      validate :forbidden_words

      alias component current_component

      def map_model(model)
        self.user_group_id = model.user_groups.first&.id
        return unless model.categorization

        self.category_id = model.categorization.decidim_category_id
      end

      private

      def question_length
        return unless body.presence
        length = current_component.settings.question_length
        errors.add(:body, :too_long, count: length) if body.length > length
      end

      def forbidden_words
        return if current_component.settings.moderation_dictionary.empty?

        contains_forbidden_words?(:title, title)
        contains_forbidden_words?(:body, body)
      end

      def contains_forbidden_words?(field_sym, field)
        return unless field.presence

        dict = current_component.settings.moderation_dictionary.downcase
        forbidden_words = dict.split("\r\n").select do |word|
          word if field.downcase.include?(word.downcase)
        end

        return if forbidden_words.empty?

        errors.add(field_sym, :forbidden_words, words: forbidden_words.join(", "))
      end
    end
  end
end
