# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    describe NotifyQuestionsMentionedJob do
      include_context "when creating a comment"
      subject { described_class }

      let(:comment) { create(:comment, commentable: commentable) }
      let(:question_component) { create(:question_component, organization: organization) }
      let(:question_metadata) { Decidim::ContentParsers::QuestionParser::Metadata.new([]) }
      let(:linked_question) { create(:question, component: question_component) }
      let(:linked_question_official) { create(:question, :official, component: question_component) }

      describe "integration" do
        it "is correctly scheduled" do
          ActiveJob::Base.queue_adapter = :test
          question_metadata[:linked_questions] << linked_question
          question_metadata[:linked_questions] << linked_question_official
          comment = create(:comment)

          expect do
            Decidim::Comments::CommentCreation.publish(comment, question: question_metadata)
          end.to have_enqueued_job.with(comment.id, question_metadata.linked_questions)
        end
      end

      describe "with mentioned questions" do
        let(:linked_questions) do
          [
            linked_question.id,
            linked_question_official.id
          ]
        end

        let!(:space_admin) do
          create(:process_admin, participatory_process: linked_question_official.component.participatory_space)
        end

        it "notifies the author about it" do
          expect(Decidim::EventsManager)
            .to receive(:publish)
            .with(
              event: "decidim.events.questions.question_mentioned",
              event_class: Decidim::Questions::QuestionMentionedEvent,
              resource: commentable,
              affected_users: [linked_question.creator_author],
              extra: {
                comment_id: comment.id,
                mentioned_question_id: linked_question.id
              }
            )

          expect(Decidim::EventsManager)
            .to receive(:publish)
            .with(
              event: "decidim.events.questions.question_mentioned",
              event_class: Decidim::Questions::QuestionMentionedEvent,
              resource: commentable,
              affected_users: [space_admin],
              extra: {
                comment_id: comment.id,
                mentioned_question_id: linked_question_official.id
              }
            )

          subject.perform_now(comment.id, linked_questions)
        end
      end
    end
  end
end
