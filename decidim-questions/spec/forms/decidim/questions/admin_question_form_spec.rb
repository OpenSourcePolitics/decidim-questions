# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    module Admin
      describe QuestionForm do
        it_behaves_like "a question form"
        it_behaves_like "a question form with meeting as author"
      end
    end
  end
end
