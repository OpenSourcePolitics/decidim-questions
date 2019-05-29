# frozen_string_literal: true

require "kaminari"
require "social-share-button"
require "ransack"
require "cells/rails"
require "cells-erb"
require "cell/partial"

module Decidim
  module Questions
    # This is the engine that runs on the public interface of `decidim-questions`.
    # It mostly handles rendering the created page associated to a participatory
    # process.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::Questions

      routes do
        resources :questions, except: [:destroy] do
          resource :question_endorsement, only: [:create, :destroy] do
            get :identities, on: :collection
          end
          member do
            get :compare
            get :complete
            get :edit_draft
            patch :update_draft
            get :preview
            post :publish
            delete :destroy_draft
            put :withdraw
          end
          resource :question_vote, only: [:create, :destroy]
          resource :question_widget, only: :show, path: "embed"
          resources :versions, only: [:show, :index]
        end
        resources :collaborative_drafts, except: [:destroy] do
          get :compare, on: :collection
          get :complete, on: :collection
          member do
            post :request_access, controller: "collaborative_draft_collaborator_requests"
            post :request_accept, controller: "collaborative_draft_collaborator_requests"
            post :request_reject, controller: "collaborative_draft_collaborator_requests"
            post :withdraw
            post :publish
          end
          resources :versions, only: [:show, :index]
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
          view_context.cell("decidim/questions/highlighted_questions", view_context.current_participatory_space)
        end

        if defined? Decidim::ParticipatoryProcesses
          Decidim::ParticipatoryProcesses.view_hooks.register(:process_group_highlighted_elements, priority: Decidim::ViewHooks::MEDIUM_PRIORITY) do |view_context|
            published_components = Decidim::Component.where(participatory_space: view_context.participatory_processes).published
            questions = Decidim::Questions::Question.published.state_visible.not_hidden.upstream_not_hidden.except_withdrawn
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
          questions = data.dig(:metadatas, :question).try(:linked_questions)
          Decidim::Questions::NotifyQuestionsMentionedJob.perform_later(data[:comment_id], questions) if questions
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

      initializer "decidim_questions.add_badges" do
        Decidim::Gamification.register_badge(:questions) do |badge|
          badge.levels = [1, 5, 10, 30, 60]

          badge.valid_for = [:user, :user_group]

          badge.reset = lambda { |model|
            if model.is_a?(User)
              Decidim::Coauthorship.where(
                coauthorable_type: "Decidim::Questions::Question",
                author: model,
                user_group: nil
              ).count
            elsif model.is_a?(UserGroup)
              Decidim::Coauthorship.where(
                coauthorable_type: "Decidim::Questions::Question",
                user_group: model
              ).count
            end
          }
        end

        Decidim::Gamification.register_badge(:accepted_questions) do |badge|
          badge.levels = [1, 5, 15, 30, 50]

          badge.valid_for = [:user, :user_group]

          badge.reset = lambda { |model|
            question_ids = if model.is_a?(User)
                             Decidim::Coauthorship.where(
                               coauthorable_type: "Decidim::Questions::Question",
                               author: model,
                               user_group: nil
                             ).select(:coauthorable_id)
                           elsif model.is_a?(UserGroup)
                             Decidim::Coauthorship.where(
                               coauthorable_type: "Decidim::Questions::Question",
                               user_group: model
                             ).select(:coauthorable_id)
                           end

            Decidim::Questions::Question.where(id: question_ids).accepted.count
          }
        end

        Decidim::Gamification.register_badge(:question_votes) do |badge|
          badge.levels = [5, 15, 50, 100, 500]

          badge.reset = lambda { |user|
            Decidim::Questions::QuestionVote.where(author: user).select(:decidim_question_id).distinct.count
          }
        end
      end

      initializer "decidim_questions.register_metrics" do
        Decidim.metrics_registry.register(:questions) do |metric_registry|
          metric_registry.manager_class = "Decidim::Questions::Metrics::QuestionsMetricManage"

          metric_registry.settings do |settings|
            settings.attribute :highlighted, type: :boolean, default: true
            settings.attribute :scopes, type: :array, default: %w(home participatory_process)
            settings.attribute :weight, type: :integer, default: 2
            settings.attribute :stat_block, type: :string, default: "medium"
          end
        end

        Decidim.metrics_registry.register(:accepted_questions) do |metric_registry|
          metric_registry.manager_class = "Decidim::Questions::Metrics::AcceptedQuestionsMetricManage"

          metric_registry.settings do |settings|
            settings.attribute :highlighted, type: :boolean, default: false
            settings.attribute :scopes, type: :array, default: %w(home participatory_process)
            settings.attribute :weight, type: :integer, default: 3
            settings.attribute :stat_block, type: :string, default: "small"
          end
        end

        Decidim.metrics_registry.register(:question_votes) do |metric_registry|
          metric_registry.manager_class = "Decidim::Questions::Metrics::VotesMetricManage"

          metric_registry.settings do |settings|
            settings.attribute :highlighted, type: :boolean, default: true
            settings.attribute :scopes, type: :array, default: %w(home participatory_process)
            settings.attribute :weight, type: :integer, default: 3
            settings.attribute :stat_block, type: :string, default: "medium"
          end
        end

        Decidim.metrics_registry.register(:question_endorsements) do |metric_registry|
          metric_registry.manager_class = "Decidim::Questions::Metrics::EndorsementsMetricManage"

          metric_registry.settings do |settings|
            settings.attribute :highlighted, type: :boolean, default: false
            settings.attribute :scopes, type: :array, default: %w(participatory_process)
            settings.attribute :weight, type: :integer, default: 4
            settings.attribute :stat_block, type: :string, default: "medium"
          end
        end

        Decidim.metrics_operation.register(:participants, :questions) do |metric_operation|
          metric_operation.manager_class = "Decidim::Questions::Metrics::QuestionParticipantsMetricMeasure"
        end
        Decidim.metrics_operation.register(:followers, :questions) do |metric_operation|
          metric_operation.manager_class = "Decidim::Questions::Metrics::QuestionFollowersMetricMeasure"
        end
      end
    end
  end
end
