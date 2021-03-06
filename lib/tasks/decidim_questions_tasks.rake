# frozen_string_literal: true

namespace :decidim do
  # Rails.logger = Logger.new(STDOUT)
  # ActiveRecord::Base.logger = Logger.new(STDOUT)

  namespace :questions do
    desc "Update all Questions with a custom reference policy"
    task update_all_custom_references: :environment do
      Decidim::Component.where(manifest_name: "questions").each do |component|
        prefix = component.name[Decidim.config.default_locale.to_s].capitalize[0]
        puts "[#{component.manifest_name.upcase}] #{component.name[Decidim.config.default_locale.to_s]}"
        current_index = 1
        Decidim::Questions::Question.where(component: component, state: %w(evaluating pending accepted)).order(published_at: :asc).each do |question|
          reference = Decidim.reference_generator.call(question, component)

          unless question.emendation?
            reference = reference + "-" + prefix + current_index.to_s
            current_index += 1
          end

          puts reference
          question.update_column(:reference, reference)
        end
      end
      # Rails.logger.close
    end # -- END OF update_all_custom_references
  end
end
