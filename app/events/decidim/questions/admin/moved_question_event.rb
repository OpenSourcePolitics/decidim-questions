# frozen-string_literal: true

module Decidim
  module Questions
    module Admin
      class MovedQuestionEvent < Decidim::Events::SimpleEvent
        include Decidim::Events::AuthorEvent

        private

        def component
          resource.component
        end

        def component_url
          @component_url  ||= main_component_url(component)
        end

        def component_name
          translated_attribute(component.try(:name))
        end

        def default_i18n_options
          super.merge({
            component_title: component_name,
            component_url: component_url
          })
        end
      end
    end
  end
end