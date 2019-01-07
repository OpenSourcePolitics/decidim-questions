# frozen_string_literal: true

require "spec_helper"

describe "Questions component" do # rubocop:disable RSpec/DescribeClass
  let!(:component) { create(:question_component) }
  let!(:current_user) { create(:user, organization: component.participatory_space.organization) }

  describe "on destroy" do
    context "when there are no questions for the component" do
      it "destroys the component" do
        expect do
          Decidim::Admin::DestroyComponent.call(component, current_user)
        end.to change { Decidim::Component.count }.by(-1)

        expect(component).to be_destroyed
      end
    end

    context "when there are questions for the component" do
      before do
        create(:question, component: component)
      end

      it "raises an error" do
        expect do
          Decidim::Admin::DestroyComponent.call(component, current_user)
        end.to broadcast(:invalid)

        expect(component).not_to be_destroyed
      end
    end
  end

  describe "stats" do
    subject { current_stat[2] }

    let(:raw_stats) do
      Decidim.component_manifests.map do |component_manifest|
        component_manifest.stats.filter(name: stats_name).with_context(component).flat_map { |name, data| [component_manifest.name, name, data] }
      end
    end

    let(:stats) do
      raw_stats.select { |stat| stat[0] == :questions }
    end

    let!(:question) { create :question }
    let(:component) { question.component }
    let!(:hidden_question) { create :question, component: component }
    let!(:draft_question) { create :question, :draft, component: component }
    let!(:withdrawn_question) { create :question, :withdrawn, component: component }
    let!(:moderation) { create :moderation, reportable: hidden_question, hidden_at: 1.day.ago }

    let(:current_stat) { stats.find { |stat| stat[1] == stats_name } }

    describe "questions_count" do
      let(:stats_name) { :questions_count }

      it "only counts published (except withdrawn) and not hidden questions" do
        expect(Decidim::Questions::Question.where(component: component).count).to eq 4
        expect(subject).to eq 1
      end
    end

    describe "votes_count" do
      let(:stats_name) { :votes_count }

      before do
        create_list :question_vote, 2, question: question
        create_list :question_vote, 3, question: hidden_question
      end

      it "counts the votes from visible questions" do
        expect(Decidim::Questions::QuestionVote.count).to eq 5
        expect(subject).to eq 2
      end
    end

    describe "endorsements_count" do
      let(:stats_name) { :endorsements_count }

      before do
        create_list :question_endorsement, 2, question: question
        create_list :question_endorsement, 3, question: hidden_question
      end

      it "counts the endorsements from visible questions" do
        expect(Decidim::Questions::QuestionEndorsement.count).to eq 5
        expect(subject).to eq 2
      end
    end

    describe "comments_count" do
      let(:stats_name) { :comments_count }

      before do
        create_list :comment, 2, commentable: question
        create_list :comment, 3, commentable: hidden_question
      end

      it "counts the comments from visible questions" do
        expect(Decidim::Comments::Comment.count).to eq 5
        expect(subject).to eq 2
      end
    end
  end
end
