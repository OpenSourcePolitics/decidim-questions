# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A form object to be used when admin users want to answer a question.
      class QuestionAnswerForm < Decidim::Form
        include Decidim::Comments::CommentsHelper
        include TranslatableAttributes

        mimic :question_answer

        translatable_attribute :answer, String
        attribute :state, String
        attribute :recipient_role, String

        validates :state, presence: true, inclusion: { in: %w(accepted rejected evaluating need_moderation) }
        validates :answer, translatable_presence: true, if: ->(form) { form.state == "rejected" }
        # validates :recipient_role, presence: true, if: ->(form) { form.question_type == "question" }

        def states(question_type, role, current_state)

          # Rails.logger.debug "-----"
          # Rails.logger.debug question_type.to_yaml
          # Rails.logger.debug role.to_yaml
          # Rails.logger.debug current_state.to_yaml
          # Rails.logger.debug "-----"

          @states = []

          if current_state.blank?
            @states.push(["rejected", I18n.t(".rejected", scope:"decidim.questions.answers")])
          end

          if question_type == "question"
            @states.push(["evaluating", I18n.t(".evaluating", scope:"decidim.questions.answers")])
            case current_state
            when "evaluating"
              @states.push(["need_moderation", I18n.t(".need_moderation", scope:"decidim.questions.answers")])
            when "need_moderation"
              @states.push(["accepted", I18n.t(".accepted", scope:"decidim.questions.answers")])
            end
          else # opinion / contribution
            @states.push(["accepted", I18n.t(".accepted", scope:"decidim.questions.answers")])
          end


          # Rails.logger.debug @states.to_yaml
          # Rails.logger.debug "-----"

          return @states

        end

      end
    end
  end
end
