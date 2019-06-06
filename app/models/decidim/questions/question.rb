# frozen_string_literal: true

module Decidim
  module Questions
    # The data store for a Question in the Decidim::Questions component.
    class Question < Questions::ApplicationRecord
      include Decidim::UpstreamReportable
      include Decidim::Resourceable
      include Decidim::Coauthorable
      include Decidim::HasComponent
      include Decidim::ScopableComponent
      include Decidim::HasReference
      include Decidim::HasCategory
      include Decidim::Reportable
      include Decidim::HasAttachments
      include Decidim::Followable
      include Decidim::Questions::CommentableQuestion
      include Decidim::Searchable
      include Decidim::Traceable
      include Decidim::Loggable
      include Decidim::Fingerprintable
      include Decidim::DataPortability
      include Decidim::Hashtaggable
      include Decidim::Questions::ParticipatoryTextSection
      include Decidim::Amendable

      attr_accessor :recipients_info

      fingerprint fields: [:title, :body]

      # Add a version on question only if the following fields are modified.
      VERSIONED_ATTRIBUTES = [:title, :body, :category]

      amendable(
        fields: [:title, :body],
        ignore: [:first_interacted_at, :published_at, :reference, :state, :answered_at, :answer],
        form: 'Decidim::Questions::QuestionForm'
      )

      component_manifest_name 'questions'

      has_many :endorsements, foreign_key: 'decidim_question_id', class_name: 'QuestionEndorsement', dependent: :destroy, counter_cache: 'question_endorsements_count'

      has_many :votes,
               -> { final },
               foreign_key: 'decidim_question_id',
               class_name: 'Decidim::Questions::QuestionVote',
               dependent: :destroy,
               counter_cache: 'question_votes_count'

      has_many :notes, foreign_key: 'decidim_question_id', class_name: 'QuestionNote', dependent: :destroy, counter_cache: 'question_notes_count'

      validates :title, :body, presence: true

      geocoded_by :address, http_headers: ->(question) { { 'Referer' => question.component.organization.host } }

      scope :accepted, -> { where(state: 'accepted') }
      scope :rejected, -> { where(state: 'rejected') }
      scope :evaluating, -> { where(state: 'evaluating') }
      scope :withdrawn, -> { where(state: 'withdrawn') }
      scope :except_rejected, -> { where.not(state: 'rejected').or(where(state: nil)) }
      scope :except_withdrawn, -> { where.not(state: 'withdrawn').or(where(state: nil)) }
      scope :drafts, -> { where(published_at: nil) }
      scope :published, -> { where.not(published_at: nil) }
      scope :state_visible, -> { where.not(state: nil) }

      acts_as_list scope: :decidim_component_id

      searchable_fields({
                            scope_id: :decidim_scope_id,
                            participatory_space: { component: :participatory_space },
                            D: :search_body,
                            A: :search_title,
                            datetime: :published_at
                        },
                        index_on_create: ->(question) { question.official? },
                        index_on_update: ->(question) { question.visible? })

      def self.order_randomly(seed)
        transaction do
          connection.execute("SELECT setseed(#{connection.quote(seed)})")
          order(Arel.sql('RANDOM()')).load
        end
      end

      def self.log_presenter_class_for(_log)
        Decidim::Questions::AdminLog::QuestionPresenter
      end

      # Returns a collection scoped by an author.
      # Overrides this method in DataPortability to support Coauthorable.
      def self.user_collection(author)
        return unless author.is_a?(Decidim::User)

        joins(:coauthorships)
            .where('decidim_coauthorships.coauthorable_type = ?', name)
            .where('decidim_coauthorships.decidim_author_id = ? AND decidim_coauthorships.decidim_author_type = ? ', author.id, author.class.base_class.name)
      end

      def self.upstream_not_hidden_for(user_role)
        upstream_not_hidden unless %w(admin committee).include?(user_role)
        all
      end

      # Public: Updates the vote count of this question.
      #
      # Returns nothing.
      def update_votes_count
        update_columns(question_votes_count: votes.count)
      end

      # rubocop:enable Rails/SkipsModelValidations

      # Public: Check if the user has voted the question.
      #
      # Returns Boolean.
      def voted_by?(user)
        QuestionVote.where(question: self, author: user).any?
      end

      # Public: Check if the user has endorsed the question.
      # - user_group: may be nil if user is not representing any user_group.
      #
      # Returns Boolean.
      def endorsed_by?(user, user_group = nil)
        endorsements.where(author: user, user_group: user_group).any?
      end

      # Public: Checks if the question has been published or not.
      #
      # Returns Boolean.
      def published?
        published_at.present?
      end

      # Public: Checks if the organization has given an answer for the question.
      #
      # Returns Boolean.
      def answered?
        answered_at.present? && state.present?
      end

      # Public: Checks if the organization has accepted a question.
      #
      # Returns Boolean.
      def accepted?
        answered? && state == 'accepted'
      end

      # Public: Checks if the organization has rejected a question.
      #
      # Returns Boolean.
      def rejected?
        answered? && state == 'rejected'
      end

      # Public: Checks if the organization has marked the question as evaluating it.
      #
      # Returns Boolean.
      def evaluating?
        answered? && state == 'evaluating'
      end

      # Public: Checks if the author has withdrawn the question.
      #
      # Returns Boolean.
      def withdrawn?
        state == 'withdrawn'
      end

      # Public: Overrides the `reported_content_url` Reportable concern method.
      def reported_content_url
        ResourceLocatorPresenter.new(self).url
      end

      # Public: Expose user side path
      def path
        Decidim::ResourceLocatorPresenter.new(self).path
      end

      # Public: Whether the question is official or not.
      def official?
        authors.first.is_a?(Decidim::Organization)
      end

      # Public: Whether the question is created in a meeting or not.
      def official_meeting?
        authors.first.class.name == 'Decidim::Meetings::Meeting'
      end

      # Public: The maximum amount of votes allowed for this question.
      #
      # Returns an Integer with the maximum amount of votes, nil otherwise.
      def maximum_votes
        maximum_votes = component.settings.threshold_per_question
        return nil if maximum_votes.zero?

        maximum_votes
      end

      # Public: The maximum amount of votes allowed for this question. 0 means infinite.
      #
      # Returns true if reached, false otherwise.
      def maximum_votes_reached?
        return false unless maximum_votes

        votes.count >= maximum_votes
      end

      # Public: Can accumulate more votres than maximum for this question.
      #
      # Returns true if can accumulate, false otherwise
      def can_accumulate_supports_beyond_threshold
        component.settings.can_accumulate_supports_beyond_threshold
      end

      # Checks whether the user can edit the given question.
      #
      # user - the user to check for authorship
      def editable_by?(user)
        return true if draft?
        !answered? && within_edit_time_limit? && !copied_from_other_component? && created_by?(user)
      end

      # Checks whether the user can withdraw the given question.
      #
      # user - the user to check for withdrawability.
      def withdrawable_by?(user)
        user && !withdrawn? && authored_by?(user) && !copied_from_other_component?
      end

      # Public: Whether the question is a draft or not.
      def draft?
        published_at.nil?
      end

      # method for sort_link by number of comments
      ransacker :commentable_comments_count do
        query = <<-SQL
        (SELECT COUNT(decidim_comments_comments.id)
         FROM decidim_comments_comments
         WHERE decidim_comments_comments.decidim_commentable_id = decidim_questions_questions.id
         AND decidim_comments_comments.decidim_commentable_type = 'Decidim::Questions::Question'
         GROUP BY decidim_comments_comments.decidim_commentable_id
         )
        SQL
        Arel.sql(query)
      end

      ransacker :is_emendation do |_parent|
        query = <<-SQL
        (
          SELECT EXISTS (
            SELECT 1 FROM decidim_amendments
            WHERE decidim_amendments.decidim_emendation_type = 'Decidim::Questions::Question'
            AND decidim_amendments.decidim_emendation_id = decidim_questions_proposals.id
          )
        )
        SQL
        Arel.sql(query)
      end

      def self.export_serializer
        Decidim::Questions::QuestionSerializer
      end

      def self.data_portability_images(user)
        user_collection(user).map { |p| p.attachments.collect(&:file) }
      end

      # Public: Overrides the `allow_resource_permissions?` Resourceable concern method.
      def allow_resource_permissions?
        component.settings.resources_permissions_enabled
      end

      # Checks whether the question is inside the time window to be editable or not once published.
      def within_edit_time_limit?
        return true if draft?
        limit = updated_at + component.settings.question_edit_before_minutes.minutes
        Time.current < limit
      end

      def short_ref
        @prefix ||= component.name[Decidim.config.default_locale.to_s].capitalize[0]
        reference.match?(%r{#{@prefix}\d+$}) ? reference.split('-').last : ""
      end

      private

      def copied_from_other_component?
        linked_resources(:questions, 'copied_from_component').any?
      end

      def participatory_space_moderators
        @participatory_space_moderators ||= get_participatory_space_moderators
      end

      def get_participatory_space_moderators
        organization_admins = participatory_space.organization.admins.pluck(:id)
        process_users = Decidim::ParticipatoryProcessUserRole
            .where(participatory_process: participatory_space)
            .where(role: [:admin, :moderator, :committee])
            .pluck(:decidim_user_id)
            .uniq
        Decidim::User.where(id: organization_admins + process_users)
      end
    end
  end
end
