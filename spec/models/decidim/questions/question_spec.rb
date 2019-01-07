# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    describe Question do
      subject { question }

      let(:component) { build :question_component }
      let(:organization) { component.participatory_space.organization }
      let(:question) { create(:question, component: component) }
      let(:coauthorable) { question }

      include_examples "coauthorable"
      include_examples "has component"
      include_examples "has scope"
      include_examples "has category"
      include_examples "has reference"
      include_examples "reportable"
      include_examples "resourceable"

      it { is_expected.to be_valid }
      it { is_expected.to be_versioned }

      it "has a votes association returning question votes" do
        expect(subject.votes.count).to eq(0)
      end

      describe "#voted_by?" do
        let(:user) { create(:user, organization: subject.organization) }

        it "returns false if the question is not voted by the given user" do
          expect(subject).not_to be_voted_by(user)
        end

        it "returns true if the question is not voted by the given user" do
          create(:question_vote, question: subject, author: user)
          expect(subject).to be_voted_by(user)
        end
      end

      describe "#endorsed_by?" do
        let(:user) { create(:user, organization: subject.organization) }

        context "with User endorsement" do
          it "returns false if the question is not endorsed by the given user" do
            expect(subject).not_to be_endorsed_by(user)
          end

          it "returns true if the question is not endorsed by the given user" do
            create(:question_endorsement, question: subject, author: user)
            expect(subject).to be_endorsed_by(user)
          end
        end

        context "with Organization endorsement" do
          let!(:user_group) { create(:user_group, verified_at: Time.current, organization: user.organization) }
          let!(:membership) { create(:user_group_membership, user: user, user_group: user_group) }

          before { user_group.reload }

          it "returns false if the question is not endorsed by the given organization" do
            expect(subject).not_to be_endorsed_by(user, user_group)
          end

          it "returns true if the question is not endorsed by the given organization" do
            create(:question_endorsement, question: subject, author: user, user_group: user_group)
            expect(subject).to be_endorsed_by(user, user_group)
          end
        end
      end

      context "when it has been accepted" do
        let(:question) { build(:question, :accepted) }

        it { is_expected.to be_answered }
        it { is_expected.to be_accepted }
      end

      context "when it has been rejected" do
        let(:question) { build(:question, :rejected) }

        it { is_expected.to be_answered }
        it { is_expected.to be_rejected }
      end

      describe "#users_to_notify_on_comment_created" do
        let!(:follows) { create_list(:follow, 3, followable: subject) }
        let(:followers) { follows.map(&:user) }
        let(:participatory_space) { subject.component.participatory_space }
        let(:organization) { participatory_space.organization }
        let!(:participatory_process_admin) do
          create(:process_admin, participatory_process: participatory_space)
        end

        context "when the question is official" do
          let(:question) { build(:question, :official) }

          it "returns the followers and the component's participatory space admins" do
            expect(subject.users_to_notify_on_comment_created).to match_array(followers.concat([participatory_process_admin]))
          end
        end

        context "when the question is not official" do
          it "returns the followers and the author" do
            expect(subject.users_to_notify_on_comment_created).to match_array(followers.concat([question.creator.author]))
          end
        end
      end

      describe "#maximum_votes" do
        let(:maximum_votes) { 10 }

        context "when the component's settings are set to an integer bigger than 0" do
          before do
            component[:settings]["global"] = { threshold_per_question: 10 }
            component.save!
          end

          it "returns the maximum amount of votes for this question" do
            expect(question.maximum_votes).to eq(10)
          end
        end

        context "when the component's settings are set to 0" do
          before do
            component[:settings]["global"] = { threshold_per_question: 0 }
            component.save!
          end

          it "returns nil" do
            expect(question.maximum_votes).to be_nil
          end
        end
      end

      describe "#editable_by?" do
        let(:author) { create(:user, organization: organization) }

        context "when user is author" do
          let(:question) { create :question, component: component, users: [author], updated_at: Time.current }

          it { is_expected.to be_editable_by(author) }

          context "when the question has been linked to another one" do
            let(:question) { create :question, component: component, users: [author], updated_at: Time.current }
            let(:original_question) do
              original_component = create(:question_component, organization: organization, participatory_space: component.participatory_space)
              create(:question, component: original_component)
            end

            before do
              question.link_resources([original_question], "copied_from_component")
            end

            it { is_expected.not_to be_editable_by(author) }
          end
        end

        context "when question is from user group and user is admin" do
          let(:user_group) { create :user_group, :verified, users: [author], organization: author.organization }
          let(:question) { create :question, component: component, updated_at: Time.current, users: [author], user_groups: [user_group] }

          it { is_expected.to be_editable_by(author) }
        end

        context "when user is not the author" do
          let(:question) { create :question, component: component, updated_at: Time.current }

          it { is_expected.not_to be_editable_by(author) }
        end

        context "when question is answered" do
          let(:question) { build :question, :with_answer, component: component, updated_at: Time.current, users: [author] }

          it { is_expected.not_to be_editable_by(author) }
        end

        context "when question editing time has run out" do
          let(:question) { build :question, updated_at: 10.minutes.ago, component: component, users: [author] }

          it { is_expected.not_to be_editable_by(author) }
        end
      end

      describe "#withdrawn?" do
        context "when question is withdrawn" do
          let(:question) { build :question, :withdrawn }

          it { is_expected.to be_withdrawn }
        end

        context "when question is not withdrawn" do
          let(:question) { build :question }

          it { is_expected.not_to be_withdrawn }
        end
      end

      describe "#withdrawable_by" do
        let(:author) { create(:user, organization: organization) }

        context "when user is author" do
          let(:question) { create :question, component: component, users: [author], created_at: Time.current }

          it { is_expected.to be_withdrawable_by(author) }
        end

        context "when user is admin" do
          let(:admin) { build(:user, :admin, organization: organization) }
          let(:question) { build :question, component: component, users: [author], created_at: Time.current }

          it { is_expected.not_to be_withdrawable_by(admin) }
        end

        context "when user is not the author" do
          let(:someone_else) { build(:user, organization: organization) }
          let(:question) { build :question, component: component, users: [author], created_at: Time.current }

          it { is_expected.not_to be_withdrawable_by(someone_else) }
        end

        context "when question is already withdrawn" do
          let(:question) { build :question, :withdrawn, component: component, users: [author], created_at: Time.current }

          it { is_expected.not_to be_withdrawable_by(author) }
        end

        context "when the question has been linked to another one" do
          let(:question) { create :question, component: component, users: [author], created_at: Time.current }
          let(:original_question) do
            original_component = create(:question_component, organization: organization, participatory_space: component.participatory_space)
            create(:question, component: original_component)
          end

          before do
            question.link_resources([original_question], "copied_from_component")
          end

          it { is_expected.not_to be_withdrawable_by(author) }
        end
      end
    end
  end
end
