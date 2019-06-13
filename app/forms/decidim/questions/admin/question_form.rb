# frozen_string_literal: true

module Decidim
  module Questions
    module Admin
      # A form object to be used when admin users want to create a question.
      class QuestionForm < Decidim::Form
        include TranslatableAttributes
        include Decidim::ApplicationHelper
        mimic :question

        attribute :title, String
        attribute :body, String
        attribute :address, String
        attribute :latitude, Float
        attribute :longitude, Float
        attribute :category_id, Integer
        attribute :scope_id, Integer
        attribute :attachment, AttachmentForm
        attribute :position, Integer
        attribute :created_in_meeting, Boolean
        attribute :meeting_id, Integer
        attribute :suggested_hashtags, Array[String]
        attribute :state, String
        attribute :recipient, String
        attribute :committee_users_ids, Array[Integer]
        attribute :service_users_ids, Array[Integer]

        translatable_attribute :answer, String

        validates :answer, translatable_presence: true, if: ->(form) { form.state == "rejected" }
        validates :state, presence: true, inclusion: { in: %w(accepted evaluating rejected) }
        validates :recipient, presence: true, inclusion: { in: %w(service committee none) }
        validates :title, :body, presence: true
        validates :title, length: { maximum: 150 }
        validates :address, geocoding: true, if: -> { current_component.settings.geocoding_enabled? }
        validates :category, presence: true, if: ->(form) { form.category_id.present? }
        validates :scope, presence: true, if: ->(form) { form.scope_id.present? }
        validates :meeting_as_author, presence: true, if: ->(form) { form.created_in_meeting? }

        validate :scope_belongs_to_participatory_space_scope
        validate :notify_missing_attachment_if_errored

        delegate :categories, to: :current_component

        def map_model(model)
          if context.blank?
            @context = {
              current_organization: model.organization,
              current_participatory_space: model.participatory_space,
              current_component: model.component
            }
          end

          self.category_id = model.categorization.try(:decidim_category_id)
          self.scope_id = model.decidim_scope_id
          self.state = "evaluating" if model.try(:state).blank?

          if model.recipient == "committee"
            self.committee_users_ids = model.recipient_ids
          elsif model.recipient == "service"
            self.service_users_ids = model.recipient_ids
          elsif model.recipient.blank? && state == "evaluating"
            self.recipient = "none"
          end

          @suggested_hashtags = Decidim::ContentRenderers::HashtagRenderer.new(model.body).extra_hashtags.map(&:name).map(&:downcase)
        end

        alias component current_component

        # Finds the Category from the category_id.
        #
        # Returns a Decidim::Category
        def category
          @category ||= categories.find_by(id: category_id)
        end

        # Finds the Scope from the given decidim_scope_id, uses participatory space scope if missing.
        #
        # Returns a Decidim::Scope
        def scope
          @scope ||= @scope_id ? current_participatory_space.scopes.find_by(id: @scope_id) : current_participatory_space.scope
        end

        # Scope identifier
        #
        # Returns the scope identifier related to the question
        def scope_id
          @scope_id || scope&.id
        end

        # Finds the Meetings of the current participatory space
        def meetings
          @meetings ||= Decidim.find_resource_manifest(:meetings).try(:resource_scope, current_component)
                               &.order(title: :asc)
        end

        # Return the meeting as author
        def meeting_as_author
          @meeting_as_author ||= meetings.find_by(id: meeting_id)
        end

        def author
          return current_organization unless created_in_meeting?

          meeting_as_author
        end

        def extra_hashtags
          @extra_hashtags ||= (component_automatic_hashtags + suggested_hashtags).uniq
        end

        def suggested_hashtags
          downcased_suggested_hashtags = Array(@suggested_hashtags&.map(&:downcase)).to_set
          component_suggested_hashtags.select { |hashtag| downcased_suggested_hashtags.member?(hashtag.downcase) }
        end

        def suggested_hashtag_checked?(hashtag)
          suggested_hashtags.member?(hashtag)
        end

        def component_automatic_hashtags
          @component_automatic_hashtags ||= ordered_hashtag_list(current_component.current_settings.automatic_hashtags)
        end

        def component_suggested_hashtags
          @component_suggested_hashtags ||= ordered_hashtag_list(current_component.current_settings.suggested_hashtags)
        end

        def available_committee_users
          @available_committee_users ||= available_users_for("committee")
        end

        def available_service_users
          @available_service_users ||= available_users_for("service")
        end

        def committee_users_ids
          fetch_users(@committee_users_ids, available_committee_users)
        end

        def service_users_ids
          fetch_users(@service_users_ids, available_service_users)
        end

        def recipient_ids
          return committee_users_ids if recipient == "committee"
          return service_users_ids if recipient == "service"

          []
        end

        private

        def available_users_for(role)
          return [] if current_participatory_space.blank?

          Decidim::ParticipatoryProcessUserRole
            .includes(:user)
            .where(participatory_process: current_participatory_space)
            .where(role: role).map(&:user)
        end

        def fetch_users(ids, collection)
          return [] if ids.blank?
          return collection.map(&:id) if ids.include?("all")

          ids = ids.compact.map(&:to_i)
          collection.select { |user| ids.include?(user.id) }.map(&:id)
        end

        def scope_belongs_to_participatory_space_scope
          errors.add(:scope_id, :invalid) if current_participatory_space.out_of_scope?(scope)
        end

        # This method will add an error to the `attachment` field only if there's
        # any error in any other field. This is needed because when the form has
        # an error, the attachment is lost, so we need a way to inform the user of
        # this problem.
        def notify_missing_attachment_if_errored
          errors.add(:attachment, :needs_to_be_reattached) if errors.any? && attachment.present?
        end

        def ordered_hashtag_list(string)
          string.to_s.split.reject(&:blank?).uniq.sort_by(&:parameterize)
        end
      end
    end
  end
end
