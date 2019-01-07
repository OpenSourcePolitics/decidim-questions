# frozen_string_literal: true

module Decidim
  module Questions
    module Metrics
      class AcceptedQuestionsMetricManage < Decidim::Questions::Metrics::QuestionsMetricManage
        def metric_name
          "accepted_questions"
        end

        private

        def query
          return @query if @query

          spaces = Decidim.participatory_space_manifests.flat_map do |manifest|
            manifest.participatory_spaces.call(@organization).public_spaces
          end
          components = Decidim::Component.where(participatory_space: spaces).published
          @query = Decidim::Questions::Question.where(component: components).joins(:component)
                                               .left_outer_joins(:category)
          @query = @query.where("decidim_questions_questions.published_at <= ?", end_time).accepted
          @query = @query.group("decidim_categorizations.id", :participatory_space_type, :participatory_space_id)
          @query
        end
      end
    end
  end
end
