# frozen-string_literal: true

module Decidim
  module Questions
    class RejectedQuestionEvent < Decidim::Events::SimpleEvent
      include Decidim::Events::AuthorEvent
    end
  end
end
