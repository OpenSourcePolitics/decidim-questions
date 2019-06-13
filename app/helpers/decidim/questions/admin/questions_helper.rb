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

        # Public: Creates a multiple select component so an admin can
        # choose which users should be the recipients of a question.
        def recipients_select(form, role, collection)
          return if collection.blank?

          content_tag(:div, class: "row column", id: "#{role}_wrapper") do
            form.select(
              role,
              collection.map { |user| [user.name, user.id] }.prepend([t("decidim.questions.admin.questions.form.all"), "all"]),
              { include_blank: false },
              multiple: true, class: "chosen-select"
            )
          end
        end
      end
    end
  end
end
