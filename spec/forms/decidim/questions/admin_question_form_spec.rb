# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    module Admin
      describe QuestionForm do
        it_behaves_like "a question form", skip_etiquette_validation: true
        it_behaves_like "a question form with meeting as author", skip_etiquette_validation: true
      end
    end
  end
end
