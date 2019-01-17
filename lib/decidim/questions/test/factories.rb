# frozen_string_literal: true

require "decidim/core/test/factories"
require "decidim/participatory_processes/test/factories"
require "decidim/meetings/test/factories"

FactoryBot.define do
  factory :question_component, parent: :component do
    name { Decidim::Components::Namer.new(participatory_space.organization.available_locales, :questions).i18n_name }
    manifest_name { :questions }
    participatory_space { create(:participatory_process, :with_steps, organization: organization) }

    trait :with_endorsements_enabled do
      step_settings do
        {
          participatory_space.active_step.id => { endorsements_enabled: true }
        }
      end
    end

    trait :with_endorsements_disabled do
      step_settings do
        {
          participatory_space.active_step.id => { endorsements_enabled: false }
        }
      end
    end

    trait :with_votes_enabled do
      step_settings do
        {
          participatory_space.active_step.id => { votes_enabled: true }
        }
      end
    end

    trait :with_votes_disabled do
      step_settings do
        {
          participatory_space.active_step.id => { votes_enabled: false }
        }
      end
    end

    trait :with_votes_hidden do
      step_settings do
        {
          participatory_space.active_step.id => { votes_hidden: true }
        }
      end
    end

    trait :with_vote_limit do
      transient do
        vote_limit { 10 }
      end

      settings do
        {
          vote_limit: vote_limit
        }
      end
    end

    trait :with_question_limit do
      transient do
        question_limit { 1 }
      end

      settings do
        {
          question_limit: question_limit
        }
      end
    end

    trait :with_question_length do
      transient do
        question_length { 500 }
      end

      settings do
        {
          question_length: question_length
        }
      end
    end

    trait :with_endorsements_blocked do
      step_settings do
        {
          participatory_space.active_step.id => {
            endorsements_enabled: true,
            endorsements_blocked: true
          }
        }
      end
    end

    trait :with_votes_blocked do
      step_settings do
        {
          participatory_space.active_step.id => {
            votes_enabled: true,
            votes_blocked: true
          }
        }
      end
    end

    trait :with_creation_enabled do
      step_settings do
        {
          participatory_space.active_step.id => { creation_enabled: true }
        }
      end
    end

    trait :with_geocoding_enabled do
      settings do
        {
          geocoding_enabled: true
        }
      end
    end

    trait :with_attachments_allowed do
      settings do
        {
          attachments_allowed: true
        }
      end
    end

    trait :with_threshold_per_question do
      transient do
        threshold_per_question { 1 }
      end

      settings do
        {
          threshold_per_question: threshold_per_question
        }
      end
    end

    trait :with_can_accumulate_supports_beyond_threshold do
      settings do
        {
          can_accumulate_supports_beyond_threshold: true
        }
      end
    end

    trait :with_collaborative_drafts_enabled do
      settings do
        {
          collaborative_drafts_enabled: true
        }
      end
    end

    trait :with_geocoding_and_collaborative_drafts_enabled do
      settings do
        {
          geocoding_enabled: true,
          collaborative_drafts_enabled: true
        }
      end
    end

    trait :with_attachments_allowed_and_collaborative_drafts_enabled do
      settings do
        {
          attachments_allowed: true,
          collaborative_drafts_enabled: true
        }
      end
    end

    trait :with_minimum_votes_per_user do
      transient do
        minimum_votes_per_user { 3 }
      end

      settings do
        {
          minimum_votes_per_user: minimum_votes_per_user
        }
      end
    end

    trait :with_participatory_texts_enabled do
      settings do
        {
          participatory_texts_enabled: true
        }
      end
    end

    trait :with_amendments_enabled do
      settings do
        {
          amendments_enabled: true
        }
      end
    end

    trait :with_amendments_and_participatory_texts_enabled do
      settings do
        {
          participatory_texts_enabled: true,
          amendments_enabled: true
        }
      end
    end

    trait :with_comments_disabled do
      settings do
        {
          comments_enabled: false
        }
      end
    end

    trait :with_extra_hashtags do
      transient do
        automatic_hashtags { "AutoHashtag AnotherAutoHashtag" }
        suggested_hashtags { "SuggestedHashtag AnotherSuggestedHashtag" }
      end

      step_settings do
        {
          participatory_space.active_step.id => {
            automatic_hashtags: automatic_hashtags,
            suggested_hashtags: suggested_hashtags,
            creation_enabled: true
          }
        }
      end
    end
  end

  factory :question, class: "Decidim::Questions::Question" do
    transient do
      users { nil }
      # user_groups correspondence to users is by sorting order
      user_groups { [] }
    end

    title { generate(:title) }
    body { Faker::Lorem.sentences(3).join("\n") }
    component { create(:question_component) }
    published_at { Time.current }
    address { "#{Faker::Address.street_name}, #{Faker::Address.city}" }

    after(:build) do |question, evaluator|
      if question.component
        users = evaluator.users || [create(:user, organization: question.component.participatory_space.organization)]
        users.each_with_index do |user, idx|
          user_group = evaluator.user_groups[idx]
          question.coauthorships.build(author: user, user_group: user_group)
        end
      end
    end

    trait :published do
      published_at { Time.current }
    end

    trait :unpublished do
      published_at { nil }
    end

    trait :official do
      after :build do |question|
        question.coauthorships.clear
        question.coauthorships.build(author: question.organization)
      end
    end

    trait :official_meeting do
      after :build do |question|
        question.coauthorships.clear
        component = create(:meeting_component, participatory_space: question.component.participatory_space)
        question.coauthorships.build(author: build(:meeting, component: component))
      end
    end

    trait :evaluating do
      state { "evaluating" }
      answered_at { Time.current }
    end

    trait :accepted do
      state { "accepted" }
      answered_at { Time.current }
    end

    trait :rejected do
      state { "rejected" }
      answered_at { Time.current }
    end

    trait :withdrawn do
      state { "withdrawn" }
    end

    trait :with_answer do
      state { "accepted" }
      answer { generate_localized_title }
      answered_at { Time.current }
    end

    trait :draft do
      published_at { nil }
    end

    trait :hidden do
      after :create do |question|
        create(:moderation, hidden_at: Time.current, reportable: question)
      end
    end

    trait :with_votes do
      after :create do |question|
        create_list(:question_vote, 5, question: question)
      end
    end

    trait :with_endorsements do
      after :create do |question|
        create_list(:question_endorsement, 5, question: question)
      end
    end
  end

  factory :question_vote, class: "Decidim::Questions::QuestionVote" do
    question { build(:question) }
    author { build(:user, organization: question.organization) }
  end

  factory :question_endorsement, class: "Decidim::Questions::QuestionEndorsement" do
    question { build(:question) }
    author { build(:user, organization: question.organization) }
  end

  factory :user_group_question_endorsement, class: "Decidim::Questions::QuestionEndorsement" do
    question { build(:question) }
    author { build(:user, organization: question.organization) }
    user_group { create(:user_group, verified_at: Time.current, organization: question.organization, users: [author]) }
  end

  factory :question_note, class: "Decidim::Questions::QuestionNote" do
    body { Faker::Lorem.sentences(3).join("\n") }
    question { build(:question) }
    author { build(:user, organization: question.organization) }
  end

  factory :collaborative_draft, class: "Decidim::Questions::CollaborativeDraft" do
    transient do
      users { nil }
      # user_groups correspondence to users is by sorting order
      user_groups { [] }
    end

    title { generate(:title) }
    body { Faker::Lorem.sentences(3).join("\n") }
    component { create(:question_component) }
    address { "#{Faker::Address.street_name}, #{Faker::Address.city}" }
    state { "open" }

    after(:build) do |collaborative_draft, evaluator|
      if collaborative_draft.component
        users = evaluator.users || [create(:user, organization: collaborative_draft.component.participatory_space.organization)]
        users.each_with_index do |user, idx|
          user_group = evaluator.user_groups[idx]
          collaborative_draft.coauthorships.build(author: user, user_group: user_group)
        end
      end
    end

    trait :published do
      state { "published" }
      published_at { Time.current }
    end

    trait :open do
      state { "open" }
    end

    trait :withdrawn do
      state { "withdrawn" }
    end
  end

  factory :participatory_text, class: "Decidim::Questions::ParticipatoryText" do
    title { Faker::Hacker.say_something_smart }
    description { Faker::Lorem.sentences(3).join("\n") }
    component { create(:question_component) }
  end

  factory :process_committee, parent: :user, class: "Decidim::User" do
    transient do
      participatory_process { create(:participatory_process) }
    end

    organization { participatory_process.organization }

    after(:create) do |user, evaluator|
      create :participatory_process_user_role,
             user: user,
             participatory_process: evaluator.participatory_process,
             role: :committee
    end
  end

  factory :process_service, parent: :user, class: "Decidim::User" do
    transient do
      participatory_process { create(:participatory_process) }
    end

    organization { participatory_process.organization }

    after(:create) do |user, evaluator|
      create :participatory_process_user_role,
             user: user,
             participatory_process: evaluator.participatory_process,
             role: :service
    end
  end
end
