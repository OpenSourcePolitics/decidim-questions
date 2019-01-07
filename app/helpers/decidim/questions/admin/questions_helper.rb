# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # This class contains helpers needed to format Meetings
      # in order to use them in select forms for Questions.
      #
      module QuestionsHelper
        # Public: A formatted collection of Meetings to be used
        # in forms.
        def meetings_as_authors_selected
          return unless @question.present? && @question.official_meeting?
          @meetings_as_authors_selected ||= @question.authors.pluck(:id)
        end
      end
    end
  end
end
