# frozen_string_literal: true

require "spec_helper"

module Decidim::Questions
  describe QuestionMCell, type: :cell do
    controller Decidim::Questions::QuestionsController

    subject { cell_html }

    let(:my_cell) { cell("decidim/questions/question_m", question, context: { show_space: show_space }) }
    let(:cell_html) { my_cell.call }
    let(:created_at) { Time.current - 1.month }
    let(:published_at) { Time.current }
    let!(:question) { create(:question, created_at: created_at, published_at: published_at) }
    let(:model) { question }
    let(:user) { create :user, organization: question.participatory_space.organization }
    let!(:emendation) { create(:question) }
    let!(:amendment) { create :amendment, amender: emendation.creator_author, amendable: question, emendation: emendation }

    before do
      allow(controller).to receive(:current_user).and_return(user)
    end

    it_behaves_like "has space in m-cell"

    context "when rendering" do
      let(:show_space) { false }

      it "renders the card" do
        expect(subject).to have_css(".card--question")
      end

      it "renders the published_at date" do
        published_date = I18n.l(published_at.to_date, format: :decidim_short)
        creation_date = I18n.l(created_at.to_date, format: :decidim_short)

        expect(subject).to have_css(".creation_date_status", text: published_date)
        expect(subject).not_to have_css(".creation_date_status", text: creation_date)
      end

      context "and is a question" do
        it "renders the question state (nil by default)" do
          expect(subject).to have_css(".muted")
          expect(subject).not_to have_css(".card__text--status")
        end
      end

      context "and is an emendation" do
        subject { cell_html }

        let(:my_cell) { cell("decidim/questions/question_m", emendation, context: { show_space: show_space }) }
        let(:cell_html) { my_cell.call }

        it "renders the emendation state (evaluating by default)" do
          expect(subject).to have_css(".warning")
          expect(subject).to have_css(".card__text--status", text: emendation.state.capitalize)
        end
      end
    end
  end
end
