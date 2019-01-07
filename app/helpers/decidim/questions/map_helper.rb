# frozen_string_literal: true

module Decidim
  module Questions
    # This helper include some methods for rendering questions dynamic maps.
    module MapHelper
      include Decidim::ApplicationHelper
      # Serialize a collection of geocoded questions to be used by the dynamic map component
      #
      # geocoded_questions - A collection of geocoded questions
      def questions_data_for_map(geocoded_questions)
        geocoded_questions.map do |question|
          question.slice(:latitude, :longitude, :address).merge(title:  present(question).title,
                                                                body: truncate(present(question).body, length: 100),
                                                                icon: icon("questions", width: 40, height: 70, remove_icon_class: true),
                                                                link: question_path(question))
        end
      end
    end
  end
end
