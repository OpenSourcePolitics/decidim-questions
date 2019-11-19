# frozen_string_literal: true

module Decidim
  module Questions
    # A question can include a notes created by admins.
    class QuestionNote < ApplicationRecord
      include Decidim::Resourceable
      # include Decidim::HasComponent
      include Decidim::Traceable
      include Decidim::Loggable

      belongs_to :question, foreign_key: "decidim_question_id", class_name: "Decidim::Questions::Question", counter_cache: true
      belongs_to :author, foreign_key: "decidim_author_id", class_name: "Decidim::User"

      delegate :component, to: :question

      default_scope { order(created_at: :asc) }

      def self.log_presenter_class_for(_log)
        Decidim::Questions::AdminLog::QuestionNotePresenter
      end
    end
  end
end
