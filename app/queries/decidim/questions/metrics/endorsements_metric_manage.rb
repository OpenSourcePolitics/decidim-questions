# frozen_string_literal: true

module Decidim
  module Questions
    module Metrics
      class EndorsementsMetricManage < Decidim::MetricManage
        def metric_name
          "endorsements"
        end

        def save
          return @registry if @registry

          @registry = []
          cumulative.each do |key, cumulative_value|
            next if cumulative_value.zero?
            quantity_value = quantity[key] || 0
            category_id, space_type, space_id, question_id = key
            record = Decidim::Metric.find_or_initialize_by(day: @day.to_s, metric_type: @metric_name,
                                                           organization: @organization, decidim_category_id: category_id,
                                                           participatory_space_type: space_type, participatory_space_id: space_id,
                                                           related_object_type: "Decidim::Questions::Question", related_object_id: question_id)
            record.assign_attributes(cumulative: cumulative_value, quantity: quantity_value)
            @registry << record
          end
          @registry.each(&:save!)
          @registry
        end

        private

        def query
          return @query if @query

          components = Decidim::Component.where(participatory_space: retrieve_participatory_spaces).published
          questions = Decidim::Questions::Question.where(component: components).except_withdrawn
          @query = Decidim::Questions::QuestionEndorsement.joins(question: :component)
                                                          .left_outer_joins(question: :category)
                                                          .where(question: questions)
          @query = @query.where("decidim_questions_question_endorsements.created_at <= ?", end_time)
          @query = @query.group("decidim_categorizations.id",
                                :participatory_space_type,
                                :participatory_space_id,
                                :decidim_question_id)
          @query
        end

        def quantity
          @quantity ||= query.where("decidim_questions_question_endorsements.created_at >= ?", start_time).count
        end
      end
    end
  end
end
