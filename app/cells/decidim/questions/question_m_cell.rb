# frozen_string_literal: true

require "cell/partial"

module Decidim
  module Questions
    # This cell renders a question with its M-size card.
    class QuestionMCell < Decidim::CardMCell
      include QuestionCellsHelper

      def badge
        render if has_badge?
      end

      def label
        return if [false, "false"].include? context[:label]
        return @label ||= t(model.question_type, scope: "decidim.questions.shared.type") if [true, "true"].include? context[:label]
        context[:label]
      end

      private

      def has_state?
        model.published?
      end

      def has_badge?
        answered? || withdrawn?
      end

      def has_link_to_resource?
        model.published?
      end

      def description
        truncate(model.body, length: 100)
      end

      def badge_classes
        return super unless options[:full_badge]
        state_classes.concat(["label", "question-status"]).join(" ")
      end

      def statuses
        return [:creation_date, :endorsements_count, :comments_count] unless has_link_to_resource?
        [:creation_date, :follow, :endorsements_count, :comments_count]
      end

      def endorsements_count_status
        return endorsements_count unless has_link_to_resource?

        link_to resource_path do
          endorsements_count
        end
      end

      def endorsements_count
        with_tooltip t("decidim.questions.models.question.fields.endorsements") do
          icon("bullhorn", class: "icon--small") + " " + model.question_endorsements_count.to_s
        end
      end

      def progress_bar_progress
        model.question_votes_count || 0
      end

      def progress_bar_total
        model.maximum_votes || 0
      end

      def progress_bar_subtitle_text
        tr_path = current_settings.votes_weight_enabled? ? "votes_weight": "votes_count"
        if progress_bar_progress >= progress_bar_total
          t("decidim.questions.questions.#{tr_path}.most_popular_question")
        else
          t("decidim.questions.questions.#{tr_path}.need_more_votes")
        end
      end
    end
  end
end
