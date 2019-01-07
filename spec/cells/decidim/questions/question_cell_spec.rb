# frozen_string_literal: true

require "spec_helper"

describe Decidim::Questions::QuestionCell, type: :cell do
  controller Decidim::Questions::QuestionsController

  subject { my_cell.call }

  let(:my_cell) { cell("decidim/questions/question", model) }
  let!(:official_question) { create(:question, :official) }
  let!(:user_question) { create(:question) }
  let!(:current_user) { create(:user, :confirmed, organization: model.participatory_space.organization) }

  before do
    allow(controller).to receive(:current_user).and_return(current_user)
  end

  context "when rendering an official question" do
    let(:model) { official_question }

    it "renders the card" do
      expect(subject).to have_css(".card--question")
    end
  end

  context "when rendering a user question" do
    let(:model) { user_question }

    it "renders the card" do
      expect(subject).to have_css(".card--question")
    end
  end
end
