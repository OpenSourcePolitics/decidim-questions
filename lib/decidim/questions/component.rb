# frozen_string_literal: true

require "decidim/components/namer"

Decidim.register_component(:questions) do |component|
  component.engine = Decidim::Questions::Engine
  component.admin_engine = Decidim::Questions::AdminEngine
  component.icon = "decidim/questions/icon.svg"
  component.admin_stylesheet = "decidim/questions/admin/component"

  component.on(:before_destroy) do |instance|
    raise "Can't destroy this component when there are questions" if Decidim::Questions::Question.where(component: instance).any?
  end

  component.data_portable_entities = ["Decidim::Questions::Question"]

  component.actions = %w(endorse vote create withdraw)

  component.query_type = "Decidim::Questions::QuestionsType"

  component.permissions_class_name = "Decidim::Questions::Permissions"

  component.settings(:global) do |settings|
    settings.attribute :upstream_moderation, type: :boolean, default: false
    settings.attribute :vote_limit, type: :integer, default: 0
    settings.attribute :minimum_votes_per_user, type: :integer, default: 0
    settings.attribute :question_limit, type: :integer, default: 0
    settings.attribute :question_length, type: :integer, default: 500
    settings.attribute :question_edit_before_minutes, type: :integer, default: 5
    settings.attribute :threshold_per_question, type: :integer, default: 0
    settings.attribute :can_accumulate_supports_beyond_threshold, type: :boolean, default: false
    settings.attribute :question_answering_enabled, type: :boolean, default: true
    settings.attribute :question_answering_roles_enabled, type: :boolean, default: true
    settings.attribute :official_questions_enabled, type: :boolean, default: true
    settings.attribute :comments_enabled, type: :boolean, default: true
    settings.attribute :geocoding_enabled, type: :boolean, default: false
    settings.attribute :attachments_allowed, type: :boolean, default: false
    settings.attribute :resources_permissions_enabled, type: :boolean, default: true
    settings.attribute :collaborative_drafts_enabled, type: :boolean, default: false
    settings.attribute :participatory_texts_enabled, type: :boolean, default: false
    settings.attribute :amendments_enabled, type: :boolean, default: false
    settings.attribute :announcement, type: :text, translated: true, editor: true
    settings.attribute :new_question_help_text, type: :text, translated: true, editor: true
    settings.attribute :question_wizard_step_1_help_text, type: :text, translated: true, editor: true
    settings.attribute :question_wizard_step_2_help_text, type: :text, translated: true, editor: true
    settings.attribute :question_wizard_step_3_help_text, type: :text, translated: true, editor: true
    settings.attribute :question_wizard_step_4_help_text, type: :text, translated: true, editor: true
  end

  component.settings(:step) do |settings|
    settings.attribute :endorsements_enabled, type: :boolean, default: true
    settings.attribute :endorsements_blocked, type: :boolean
    settings.attribute :votes_enabled, type: :boolean
    settings.attribute :votes_blocked, type: :boolean
    settings.attribute :votes_hidden, type: :boolean, default: false
    settings.attribute :comments_blocked, type: :boolean, default: false
    settings.attribute :creation_enabled, type: :boolean
    settings.attribute :question_answering_enabled, type: :boolean, default: true
    settings.attribute :announcement, type: :text, translated: true, editor: true
    settings.attribute :automatic_hashtags, type: :text, editor: false, required: false
    settings.attribute :suggested_hashtags, type: :text, editor: false, required: false
  end

  component.register_resource(:question) do |resource|
    resource.model_class_name = "Decidim::Questions::Question"
    resource.template = "decidim/questions/questions/linked_questions"
    resource.card = "decidim/questions/question"
    resource.actions = %w(endorse vote)
    resource.searchable = true
  end

  component.register_resource(:collaborative_draft) do |resource|
    resource.model_class_name = "Decidim::Questions::CollaborativeDraft"
    resource.card = "decidim/questions/collaborative_draft"
  end

  component.register_stat :questions_count, primary: true, priority: Decidim::StatsRegistry::HIGH_PRIORITY do |components, start_at, end_at|
    Decidim::Questions::FilteredQuestions.for(components, start_at, end_at).published.state_visible.except_withdrawn.not_hidden.upstream_not_hidden.count
  end

  component.register_stat :questions_accepted, primary: true, priority: Decidim::StatsRegistry::HIGH_PRIORITY do |components, start_at, end_at|
    Decidim::Questions::FilteredQuestions.for(components, start_at, end_at).accepted.count
  end

  component.register_stat :votes_count, priority: Decidim::StatsRegistry::HIGH_PRIORITY do |components, start_at, end_at|
    questions = Decidim::Questions::FilteredQuestions.for(components, start_at, end_at).published.state_visible.not_hidden.upstream_not_hidden
    Decidim::Questions::QuestionVote.where(question: questions).count
  end

  component.register_stat :endorsements_count, priority: Decidim::StatsRegistry::MEDIUM_PRIORITY do |components, start_at, end_at|
    questions = Decidim::Questions::FilteredQuestions.for(components, start_at, end_at).not_hidden.upstream_not_hidden
    Decidim::Questions::QuestionEndorsement.where(question: questions).count
  end

  component.register_stat :comments_count, tag: :comments do |components, start_at, end_at|
    questions = Decidim::Questions::FilteredQuestions.for(components, start_at, end_at).published.not_hidden.upstream_not_hidden
    Decidim::Comments::Comment.where(root_commentable: questions).count
  end

  component.exports :questions do |exports|
    exports.collection do |component_instance|
      Decidim::Questions::Question
        .published
        .where(component: component_instance)
        .includes(:category, component: { participatory_space: :organization })
    end

    exports.include_in_open_data = true

    exports.serializer Decidim::Questions::QuestionSerializer
  end

  component.exports :comments do |exports|
    exports.collection do |component_instance|
      Decidim::Comments::Export.comments_for_resource(
        Decidim::Questions::Question, component_instance
      )
    end

    exports.serializer Decidim::Comments::CommentSerializer
  end

  component.seeds do |participatory_space|
    admin_user = Decidim::User.find_by(
      organization: participatory_space.organization,
      email: "admin@example.org"
    )

    step_settings = if participatory_space.allows_steps?
                      { participatory_space.active_step.id => { votes_enabled: true, votes_blocked: false, creation_enabled: true } }
                    else
                      {}
                    end

    params = {
      name: Decidim::Components::Namer.new(participatory_space.organization.available_locales, :questions).i18n_name,
      manifest_name: :questions,
      published_at: Time.current,
      participatory_space: participatory_space,
      settings: {
        vote_limit: 0,
        collaborative_drafts_enabled: true,
        question_answering_enabled: true,
        question_answering_roles_enabled: true
      },
      step_settings: step_settings
    }

    component = Decidim.traceability.perform_action!(
      "publish",
      Decidim::Component,
      admin_user,
      visibility: "all"
    ) do
      Decidim::Component.create!(params)
    end

    if participatory_space.scope
      scopes = participatory_space.scope.descendants
      global = participatory_space.scope
    else
      scopes = participatory_space.organization.scopes
      global = nil
    end

    5.times do |n|
      state, answer = if n > 3
                        ["accepted", Decidim::Faker::Localized.sentence(10)]
                      elsif n > 2
                        ["rejected", nil]
                      elsif n > 1
                        ["evaluating", nil]
                      else
                        [nil, nil]
                      end

      params = {
        component: component,
        category: participatory_space.categories.sample,
        scope: Faker::Boolean.boolean(0.5) ? global : scopes.sample,
        title: Faker::Lorem.sentence(2),
        body: Faker::Lorem.paragraphs(2).join("\n"),
        state: state,
        answer: answer,
        answered_at: Time.current,
        published_at: Time.current
      }

      question = Decidim.traceability.perform_action!(
        "publish",
        Decidim::Questions::Question,
        admin_user,
        visibility: "all"
      ) do
        question = Decidim::Questions::Question.new(params)
        question.add_coauthor(participatory_space.organization)
        question.save!
        question
      end

      if n.positive?
        Decidim::User.where(decidim_organization_id: participatory_space.decidim_organization_id).all.sample(n).each do |author|
          user_group = [true, false].sample ? Decidim::UserGroups::ManageableUserGroups.for(author).verified.sample : nil
          question.add_coauthor(author, user_group: user_group)
        end
      end

      if question.state.nil?
        email = "amendment-author-#{participatory_space.underscored_name}-#{participatory_space.id}-#{n}-amend#{n}@example.org"
        name = "#{Faker::Name.name} #{participatory_space.id} #{n} amend#{n}"

        author = Decidim::User.find_or_initialize_by(email: email)
        author.update!(
          password: "password1234",
          password_confirmation: "password1234",
          name: name,
          nickname: Faker::Twitter.unique.screen_name,
          organization: component.organization,
          tos_agreement: "1",
          confirmed_at: Time.current
        )

        group = Decidim::UserGroup.create!(
          name: Faker::Name.name,
          nickname: Faker::Twitter.unique.screen_name,
          email: Faker::Internet.email,
          extended_data: {
            document_number: Faker::Code.isbn,
            phone: Faker::PhoneNumber.phone_number,
            verified_at: Time.current
          },
          decidim_organization_id: component.organization.id
        )
        group.confirm
        Decidim::UserGroupMembership.create!(
          user: author,
          role: "creator",
          user_group: group
        )

        params = {
          component: component,
          category: participatory_space.categories.sample,
          scope: Faker::Boolean.boolean(0.5) ? global : scopes.sample,
          title: "#{question.title} #{Faker::Lorem.sentence(1)}",
          body: "#{question.body} #{Faker::Lorem.sentence(3)}",
          state: nil,
          answer: nil,
          answered_at: Time.current,
          published_at: Time.current
        }

        emendation = Decidim.traceability.perform_action!(
          "create",
          Decidim::Questions::Question,
          author,
          visibility: "public-only"
        ) do
          emendation = Decidim::Questions::Question.new(params)
          emendation.add_coauthor(author, user_group: author.user_groups.first)
          emendation.save!
          emendation
        end

        Decidim::Amendment.create!(
          amender: author,
          amendable: question,
          emendation: emendation,
          state: "evaluating"
        )
      end

      (n % 3).times do |m|
        email = "vote-author-#{participatory_space.underscored_name}-#{participatory_space.id}-#{n}-#{m}@example.org"
        name = "#{Faker::Name.name} #{participatory_space.id} #{n} #{m}"

        author = Decidim::User.find_or_initialize_by(email: email)
        author.update!(
          password: "password1234",
          password_confirmation: "password1234",
          name: name,
          nickname: Faker::Twitter.unique.screen_name,
          organization: component.organization,
          tos_agreement: "1",
          confirmed_at: Time.current,
          personal_url: Faker::Internet.url,
          about: Faker::Lorem.paragraph(2)
        )

        Decidim::Questions::QuestionVote.create!(question: question, author: author) unless question.answered? && question.rejected?
        Decidim::Questions::QuestionVote.create!(question: emendation, author: author) if emendation
      end

      unless question.answered? && question.rejected?
        (n * 2).times do |index|
          email = "endorsement-author-#{participatory_space.underscored_name}-#{participatory_space.id}-#{n}-endr#{index}@example.org"
          name = "#{Faker::Name.name} #{participatory_space.id} #{n} endr#{index}"

          author = Decidim::User.find_or_initialize_by(email: email)
          author.update!(
            password: "password1234",
            password_confirmation: "password1234",
            name: name,
            nickname: Faker::Twitter.unique.screen_name,
            organization: component.organization,
            tos_agreement: "1",
            confirmed_at: Time.current
          )
          if index.even?
            group = Decidim::UserGroup.create!(
              name: Faker::Name.name,
              nickname: Faker::Twitter.unique.screen_name,
              email: Faker::Internet.email,
              extended_data: {
                document_number: Faker::Code.isbn,
                phone: Faker::PhoneNumber.phone_number,
                verified_at: Time.current
              },
              decidim_organization_id: component.organization.id
            )
            group.confirm
            Decidim::UserGroupMembership.create!(
              user: author,
              role: "creator",
              user_group: group
            )
          end
          Decidim::Questions::QuestionEndorsement.create!(question: question, author: author, user_group: author.user_groups.first)
        end
      end

      (n % 3).times do
        author_admin = Decidim::User.where(organization: component.organization, admin: true).all.sample

        Decidim::Questions::QuestionNote.create!(
          question: question,
          author: author_admin,
          body: Faker::Lorem.paragraphs(2).join("\n")
        )
      end

      Decidim::Comments::Seed.comments_for(question)

      #
      # Collaborative drafts
      #
      state = if n > 3
                "published"
              elsif n > 2
                "withdrawn"
              else
                "open"
              end
      author = Decidim::User.where(organization: component.organization).all.sample

      draft = Decidim.traceability.perform_action!("create", Decidim::Questions::CollaborativeDraft, author) do
        draft = Decidim::Questions::CollaborativeDraft.new(
          component: component,
          category: participatory_space.categories.sample,
          scope: Faker::Boolean.boolean(0.5) ? global : scopes.sample,
          title: Faker::Lorem.sentence(2),
          body: Faker::Lorem.paragraphs(2).join("\n"),
          state: state,
          published_at: Time.current
        )
        draft.coauthorships.build(author: participatory_space.organization)
        draft.save!
        draft
      end

      if n == 2
        author2 = Decidim::User.where(organization: component.organization).all.sample
        Decidim::Coauthorship.create(coauthorable: draft, author: author2)
        author3 = Decidim::User.where(organization: component.organization).all.sample
        Decidim::Coauthorship.create(coauthorable: draft, author: author3)
        author4 = Decidim::User.where(organization: component.organization).all.sample
        Decidim::Coauthorship.create(coauthorable: draft, author: author4)
        author5 = Decidim::User.where(organization: component.organization).all.sample
        Decidim::Coauthorship.create(coauthorable: draft, author: author5)
        author6 = Decidim::User.where(organization: component.organization).all.sample
        Decidim::Coauthorship.create(coauthorable: draft, author: author6)
      elsif n == 3
        author2 = Decidim::User.where(organization: component.organization).all.sample
        Decidim::Coauthorship.create(coauthorable: draft, author: author2)
      end

      Decidim::Comments::Seed.comments_for(draft)
    end

    Decidim.traceability.update!(
      Decidim::Questions::CollaborativeDraft.all.sample,
      Decidim::User.where(organization: component.organization).all.sample,
      component: component,
      category: participatory_space.categories.sample,
      scope: Faker::Boolean.boolean(0.5) ? global : scopes.sample,
      title: Faker::Lorem.sentence(2),
      body: Faker::Lorem.paragraphs(2).join("\n")
    )
  end
end
