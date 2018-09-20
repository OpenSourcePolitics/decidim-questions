# frozen_string_literal: true

require_dependency "decidim/components/namer"

Decidim.register_component(:questions) do |component|
  component.engine = Decidim::Questions::Engine
  component.admin_engine = Decidim::Questions::AdminEngine
  component.icon = "decidim/questions/icon.svg"

  component.on(:before_destroy) do |instance|
    # Code executed before removing the component
    raise "Can't destroy this component when there are questions" if Decidim::Questions::Question.where(component: instance).any?
  end

  # These actions permissions can be configured in the admin panel
  component.actions = %w(endorse vote create withdraw answer)

  component.query_type = "Decidim::Questions::QuestionsType"

  component.permissions_class_name = "Decidim::Questions::Permissions"


  component.settings(:global) do |settings|
    # Add your global settings
    # Available types: :integer, :boolean
    settings.attribute :vote_limit, type: :integer, default: 0
    settings.attribute :question_limit, type: :integer, default: 0
    settings.attribute :question_length, type: :integer, default: 500
    settings.attribute :question_edit_before_minutes, type: :integer, default: 5
    settings.attribute :threshold_per_question, type: :integer, default: 0
    settings.attribute :can_accumulate_supports_beyond_threshold, type: :boolean, default: false
    settings.attribute :question_answering_enabled, type: :boolean, default: true
    settings.attribute :official_questions_enabled, type: :boolean, default: true
    settings.attribute :comments_enabled, type: :boolean, default: true
    settings.attribute :geocoding_enabled, type: :boolean, default: false
    settings.attribute :attachments_allowed, type: :boolean, default: false
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
    settings.attribute :votes_weight_enabled, type: :boolean
    settings.attribute :votes_blocked, type: :boolean
    settings.attribute :votes_hidden, type: :boolean, default: false
    settings.attribute :comments_blocked, type: :boolean, default: false
    settings.attribute :creation_enabled, type: :boolean
    settings.attribute :question_answering_enabled, type: :boolean, default: true
    settings.attribute :announcement, type: :text, translated: true, editor: true
  end

  component.register_resource(:some_resource) do |resource|
    # Register a optional resource that can be references from other resources.
    resource.model_class_name = "Decidim::Questions::Question"
    resource.template = "decidim/questions/questions/linked_questions"
    resource.card = "decidim/questions/question"
  end

  component.register_stat :questions_count, primary: true, priority: Decidim::StatsRegistry::HIGH_PRIORITY do |components, start_at, end_at|
    Decidim::Questions::FilteredQuestions.for(components, start_at, end_at).published.except_withdrawn.not_hidden.count
  end

  component.register_stat :questions_accepted, primary: true, priority: Decidim::StatsRegistry::HIGH_PRIORITY do |components, start_at, end_at|
    Decidim::Questions::FilteredQuestions.for(components, start_at, end_at).accepted.count
  end

  component.register_stat :votes_count, priority: Decidim::StatsRegistry::HIGH_PRIORITY do |components, start_at, end_at|
    questions = Decidim::Questions::FilteredQuestions.for(components, start_at, end_at).published.not_hidden
    Decidim::Questions::QuestionVote.where(question: questions).count
  end

  component.register_stat :endorsements_count, priority: Decidim::StatsRegistry::MEDIUM_PRIORITY do |components, start_at, end_at|
    questions = Decidim::Questions::FilteredQuestions.for(components, start_at, end_at).not_hidden
    Decidim::Questions::QuestionEndorsement.where(question: questions).count
  end

  component.register_stat :comments_count, tag: :comments do |components, start_at, end_at|
    questions = Decidim::Questions::FilteredQuestions.for(components, start_at, end_at).published.not_hidden
    Decidim::Comments::Comment.where(root_commentable: questions).count
  end

  component.exports :questions do |exports|
    exports.collection do |component_instance|
      Decidim::Questions::Question
        .where(component: component_instance)
        .includes(:category, component: { participatory_space: :organization })
    end

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
    step_settings = if participatory_space.allows_steps?
                      { participatory_space.active_step.id => { votes_enabled: true, votes_blocked: false, creation_enabled: true } }
                    else
                      {}
                    end

    component = Decidim::Component.create!(
      name: Decidim::Components::Namer.new(participatory_space.organization.available_locales, :questions).i18n_name,
      manifest_name: :questions,
      published_at: Time.current,
      participatory_space: participatory_space,
      settings: {
        vote_limit: 0
      },
      step_settings: step_settings
    )

    if participatory_space.scope
      scopes = participatory_space.scope.descendants
      global = participatory_space.scope
    else
      scopes = participatory_space.organization.scopes
      global = nil
    end

    5.times do |n|
      author = Decidim::User.where(organization: component.organization).all.sample
      user_group = [true, false].sample ? author.user_groups.verified.sample : nil
      state, answer, recipient_role = if n > 3
                        ["accepted", Decidim::Faker::Localized.sentence(10), ]
                      elsif n > 2
                        ["rejected", nil]
                      elsif n > 1
                        ["evaluating", nil]
                      else
                        [nil, nil]
                      end

      question = Decidim::Questions::Question.create!(
        component: component,
        category: participatory_space.categories.sample,
        scope: Faker::Boolean.boolean(0.5) ? global : scopes.sample,
        title: Faker::Lorem.sentence(2),
        body: Faker::Lorem.paragraphs(2).join("\n"),
        author: author,
        user_group: user_group,
        state: state,
        question_type: Decidim::Questions::Question::TYPES.sample,
        recipient_role: %w(service committee).sample,
        answer: answer,
        answered_at: Time.current,
        published_at: Time.current
      )

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
              document_number: Faker::Code.isbn,
              phone: Faker::PhoneNumber.phone_number,
              decidim_organization_id: component.organization.id,
              verified_at: Time.current
            )
            author.user_groups << group
            author.save!
          end
          Decidim::Questions::QuestionEndorsement.create!(question: question, author: author, user_group: author.user_groups.first)
        end
      end

      (n % 5).times do
        author_admin = Decidim::User.where(organization: component.organization, admin: true).all.sample

        Decidim::Questions::QuestionNote.create!(
          question: question,
          author: author_admin,
          body: Faker::Lorem.paragraphs(2).join("\n")
        )
      end

      Decidim::Comments::Seed.comments_for(question)
    end
  end
end
