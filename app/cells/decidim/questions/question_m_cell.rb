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

      private

      def title
        if %w(evaluating accepted).include?(model.state)
          model.short_ref + ' • ' + present(model).title
        else
          present(model).title
        end
      end

      def body
        present(model).body
      end

      def has_state?
        model.published?
      end

      def has_badge?
        answered? || withdrawn? || emendation?
      end

      def has_link_to_resource?
        model.published?
      end

      def has_footer?
        return false if model.emendation?
        true
      end

      def description
        html = present(model).body
        safe = strip_tags(html)
        truncate(safe, length: 100)
      end

      def badge_classes
        return super unless options[:full_badge]
        state_classes.concat(["label", "question-status"]).join(" ")
      end

      def statuses
        return [:endorsements_count, :comments_count] if model.draft?
        return [:creation_date, :endorsements_count, :comments_count] unless has_link_to_resource?
        [:creation_date, :follow, :endorsements_count, :comments_count]
      end

      def creation_date_status
        l(model.published_at.to_date, format: :decidim_short)
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
        if progress_bar_progress >= progress_bar_total
          t("decidim.questions.questions.votes_count.most_popular_question")
        else
          t("decidim.questions.questions.votes_count.need_more_votes")
        end
      end
    end
  end
end
