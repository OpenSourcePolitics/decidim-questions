# frozen_string_literal: true

module Decidim
  module Questions
    module AdminLog
      # This class holds the logic to present a `Decidim::Questions::Question`
      # for the `AdminLog` log.
      #
      # Usage should be automatic and you shouldn't need to call this class
      # directly, but here's an example:
      #
      #    action_log = Decidim::ActionLog.last
      #    view_helpers # => this comes from the views
      #    QuestionPresenter.new(action_log, view_helpers).present
      class QuestionPresenter < Decidim::Log::BasePresenter
        private

        def resource_presenter
          @resource_presenter ||= Decidim::Questions::Log::ResourcePresenter.new(action_log.resource, h, action_log.extra["resource"])
        end

        def diff_fields_mapping
          {
            title: "Decidim::Questions::AdminLog::ValueTypes::QuestionTitleBodyPresenter",
            body: "Decidim::Questions::AdminLog::ValueTypes::QuestionTitleBodyPresenter",
            state: "Decidim::Questions::AdminLog::ValueTypes::QuestionStatePresenter",
            answered_at: :date,
            answer: :i18n
          }
        end

        def action_string
          case action
          when "answer", "create", "update"
            "decidim.questions.admin_log.question.#{action}"
          else
            super
          end
        end

        def i18n_labels_scope
          "activemodel.attributes.question"
        end

        def has_diff?
          action == "answer" || super
        end
      end
    end
  end
end
