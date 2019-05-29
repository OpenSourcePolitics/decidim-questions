# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    describe QuestionActivityCell, type: :cell do
      controller Decidim::LastActivitiesController

      let!(:question) { create(:question) }
      let(:hashtag) { create(:hashtag, name: "myhashtag") }
      let(:action_log) do
        create(
          :action_log,
          resource: question,
          organization: question.organization,
          component: question.component,
          participatory_space: question.participatory_space
        )
      end

      context "when rendering" do
        it "renders the card" do
          html = cell("decidim/questions/question_activity", action_log).call
          expect(html).to have_css(".card-data")
          expect(html).to have_content("New question")
        end

        context "when the question has a hashtags" do
          before do
            body = "Question with #myhashtag"
            parsed_body = Decidim::ContentProcessor.parse(body, current_organization: question.organization)
            question.body = parsed_body.rewrite
            question.save
          end

          it "correctly renders questions with mentions" do
            html = cell("decidim/questions/question_activity", action_log).call
            expect(html).to have_no_content("gid://")
            expect(html).to have_content("#myhashtag")
          end
        end
      end
    end
  end
end
