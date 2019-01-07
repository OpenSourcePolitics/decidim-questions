# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A form object to be used when admin users wants to split two or more
      # questions into a new one to another question component in the same space.
      class QuestionsSplitForm < QuestionsForkForm
      end
    end
  end
end
