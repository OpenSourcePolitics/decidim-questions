# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A form object to be used when admin users wants to merge two or more
      # questions into a new one to another question component in the same space.
      class QuestionsMergeForm < QuestionsForkForm
        validates :questions, length: { minimum: 2 }
      end
    end
  end
end
