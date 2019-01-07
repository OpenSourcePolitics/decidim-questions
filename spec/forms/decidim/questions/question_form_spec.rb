# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    describe QuestionForm do
      let(:params) do
        super.merge(
          user_group_id: user_group_id
        )
      end

      it_behaves_like "a question form", user_group_check: true
    end
  end
end
