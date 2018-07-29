# frozen_string_literal: true

module Decidim
  module Questions
    # The data store for a Question in the Decidim::Questions component.
    class Question < Questions::ApplicationRecord
      include Decidim::Resourceable
      include Decidim::Authorable
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

      fingerprint fields: [:title, :body]

      component_manifest_name "questions"

      has_many :endorsements, foreign_key: "decidim_question_id", class_name: "QuestionEndorsement", dependent: :destroy, counter_cache: "question_endorsements_count"
      has_many :votes, foreign_key: "decidim_question_id", class_name: "QuestionVote", dependent: :destroy, counter_cache: "question_votes_count"
      has_many :notes, foreign_key: "decidim_question_id", class_name: "QuestionNote", dependent: :destroy, counter_cache: "question_notes_count"

      # Votes weight
      has_many :up_votes, -> { where(weight: 1) }, foreign_key: "decidim_questions_id", class_name: "QuestionVote", dependent: :destroy
      has_many :down_votes, -> { where(weight: -1) }, foreign_key: "decidim_questions_id", class_name: "QuestionVote", dependent: :destroy
      has_many :neutral_votes, -> { where(weight: 0) }, foreign_key: "decidim_questions_id", class_name: "QuestionVote", dependent: :destroy

      validates :title, :body, presence: true

      TYPES = %w(question opinion contribution).freeze
      validates :question_type, presence: true, inclusion: { in: TYPES }

      geocoded_by :address, http_headers: ->(question) { { "Referer" => question.component.organization.host } }

      scope :accepted, -> { where(state: "accepted") }
      scope :rejected, -> { where(state: "rejected") }
      scope :evaluating, -> { where(state: "evaluating") }
      scope :withdrawn, -> { where(state: "withdrawn") }
      scope :except_rejected, -> { where.not(state: "rejected").or(where(state: nil)) }
      scope :except_withdrawn, -> { where.not(state: "withdrawn").or(where(state: nil)) }
      scope :published, -> { where.not(published_at: nil) }

      searchable_fields({
                          scope_id: :decidim_scope_id,
                          participatory_space: { component: :participatory_space },
                          A: :title,
                          D: :body,
                          datetime: :published_at
                        },
                        index_on_create: false,
                        index_on_update: ->(question) { question.visible? })

      def self.order_randomly(seed)
        transaction do
          connection.execute("SELECT setseed(#{connection.quote(seed)})")
          order(Arel.sql("RANDOM()")).load
        end
      end

      def self.log_presenter_class_for(_log)
        Decidim::Questions::AdminLog::QuestionPresenter
      end

      # Public: Check if the user has voted the question.
      #
      # Returns Boolean.
      def voted_by?(user)
        votes.where(author: user).any?
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
        answered? && state == "accepted"
      end

      # Public: Checks if the organization has rejected a question.
      #
      # Returns Boolean.
      def rejected?
        answered? && state == "rejected"
      end

      # Public: Checks if the organization has marked the question as evaluating it.
      #
      # Returns Boolean.
      def evaluating?
        answered? && state == "evaluating"
      end

      # Public: Checks if the author has withdrawn the question.
      #
      # Returns Boolean.
      def withdrawn?
        state == "withdrawn"
      end

      # Public: Overrides the `reported_content_url` Reportable concern method.
      def reported_content_url
        ResourceLocatorPresenter.new(self).url
      end


      # Public: Whether the question is official or not.
      def official?
        author.nil?
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
        authored_by?(user) && !answered? && within_edit_time_limit? && !copied_from_other_component?
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

      def up_voted_by?(user)
        votes.where(author: user,  questions: self, weight: 1).any?
      end

      def neutral_voted_by?(user)
        votes.where(author: user,  questions: self, weight: 0).any?
      end

      def down_voted_by?(user)
        votes.where(author: user,  questions: self, weight: -1).any?
      end

      def weighted_by?(user,value)
        case value
        when 'up' then up_voted_by?(user)
          when 'neutral' then neutral_voted_by?(user)
          when 'down' then down_voted_by?(user)
          else false
        end
      end

      def users_to_notify_on_questions_created
        get_all_users_with_role
      end

      def users_to_notify_on_comment_created
        get_all_users_with_role
      end

      private

      # Checks whether the question is inside the time window to be editable or not once published.
      def within_edit_time_limit?
        return true if draft?
        limit = updated_at + component.settings.question_edit_before_minutes.minutes
        Time.current < limit
      end

      def copied_from_other_component?
        linked_resources(:questions, "copied_from_component").any?
      end
    end
  end
end
