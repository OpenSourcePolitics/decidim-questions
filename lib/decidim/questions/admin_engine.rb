# frozen_string_literal: true

module Decidim
  module Questions
    # This is the engine that runs on the public interface of `Questions`.
    class AdminEngine < ::Rails::Engine
      isolate_namespace Decidim::Questions::Admin

      paths["db/migrate"] = nil

      routes do
        resources :questions, only: [:index, :new, :create] do
          post :update_category, on: :collection
          collection do
            resource :questions_import, only: [:new, :create]
          end
          resources :question_answers, only: [:edit, :update]
          resources :question_notes, only: [:index, :create]
        end
        root to: "questions#index"
      end

      initializer "decidim_questions.admin_assets" do |app|
        app.config.assets.precompile += %w(admin/decidim_questions_manifest.js
                                            admin/decidim_questions_manifest.css)
      end

      def load_seed
        nil
      end
    end
  end
end
