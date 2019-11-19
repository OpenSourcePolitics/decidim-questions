# frozen_string_literal: true

module Decidim
  module Questions
    module Events
      autoload :QuestionEvent, "decidim/questions/events/question_event"
      autoload :WorkflowEvent, "decidim/questions/events/workflow_event"
    end
  end
end
