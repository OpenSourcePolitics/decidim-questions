# frozen_string_literal: true

require "rails"
require "kaminari"
require "social-share-button"
require "ransack"
require "cells/rails"
require "cells-erb"
require "cell/partial"
require "decidim/core"

module Decidim
  module Questions
    # This is the engine that runs on the public interface of questions.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::Questions

      routes do
        resources :questions, except: [:destroy] do
          resource :question_endorsement, only: [:create, :destroy] do
            get :identities, on: :collection
          end
          get :compare, on: :collection
          get :complete, on: :collection
          member do
            get :edit_draft
            patch :update_draft
            get :preview
            post :publish
            delete :destroy_draft
            put :withdraw
          end
          resource :question_vote, only: [:create, :destroy]
          resource :question_widget, only: :show, path: "embed"
        end
        root to: "questions#index"
      end

      initializer "decidim_questions.assets" do |app|
        app.config.assets.precompile += %w(decidim_questions_manifest.js
                                           decidim_questions_manifest.css
                                           decidim/questions/identity_selector_dialog.js)
      end

      initializer "decidim.content_processors" do |_app|
        Decidim.configure do |config|
          config.content_processors += [:question]
        end
      end

      initializer "decidim_questions.view_hooks" do
        Decidim.view_hooks.register(:participatory_space_highlighted_elements, priority: Decidim::ViewHooks::MEDIUM_PRIORITY) do |view_context|
          published_components = Decidim::Component.where(participatory_space: view_context.current_participatory_space).published
          questions = Decidim::Questions::Question.published.not_hidden.except_withdrawn
                                                  .where(component: published_components)
                                                  .order_randomly(rand * 2 - 1)
                                                  .limit(Decidim::Questions.config.participatory_space_highlighted_questions_limit)

          next unless questions.any?

          view_context.extend Decidim::Questions::ApplicationHelper
          view_context.render(
            partial: "decidim/participatory_spaces/highlighted_questions",
            locals: {
              questions: questions
            }
          )
        end

        if defined? Decidim::ParticipatoryProcesses
          Decidim::ParticipatoryProcesses.view_hooks.register(:process_group_highlighted_elements, priority: Decidim::ViewHooks::MEDIUM_PRIORITY) do |view_context|
            published_components = Decidim::Component.where(participatory_space: view_context.participatory_processes).published
            questions = Decidim::Questions::Question.published.not_hidden.except_withdrawn
                                                    .where(component: published_components)
                                                    .order_randomly(rand * 2 - 1)
                                                    .limit(Decidim::Questions.config.process_group_highlighted_questions_limit)

            next unless questions.any?

            view_context.extend Decidim::ResourceReferenceHelper
            view_context.extend Decidim::Questions::ApplicationHelper
            view_context.render(
              partial: "decidim/participatory_processes/participatory_process_groups/highlighted_questions",
              locals: {
                questions: questions
              }
            )
          end
        end
      end

      initializer "decidim_changes" do
        Decidim::SettingsChange.subscribe "surveys" do |changes|
          Decidim::Questions::SettingsChangeJob.perform_later(
            changes[:component_id],
            changes[:previous_settings],
            changes[:current_settings]
          )
        end
      end

      initializer "decidim_questions.mentions_listener" do
        Decidim::Comments::CommentCreation.subscribe do |data|
          metadata = data[:metadatas][:questions]
          Decidim::Questions::NotifyQuestionsMentionedJob.perform_later(data[:comment_id], metadata)
        end
      end

      # Subscribes to ActiveSupport::Notifications that may affect a Question.
      initializer "decidim_questions.subscribe_to_events" do
        # when a question is linked from a result
        event_name = "decidim.resourceable.included_questions.created"
        ActiveSupport::Notifications.subscribe event_name do |_name, _started, _finished, _unique_id, data|
          payload = data[:this]
          if payload[:from_type] == Decidim::Accountability::Result.name && payload[:to_type] == Question.name
            question = Question.find(payload[:to_id])
            question.update(state: "accepted")
          end
        end
      end

      initializer "decidim_questions.add_cells_view_paths" do
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::Questions::Engine.root}/app/cells")
        Cell::ViewModel.view_paths << File.expand_path("#{Decidim::Questions::Engine.root}/app/views") # for question partials
      end
    end
  end
end
