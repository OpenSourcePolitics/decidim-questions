# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Amendable
    describe Withdraw do
      let!(:question) { create(:question) }
      let!(:emendation) { create(:question) }
      let!(:amendment) { create :amendment, amendable: question, emendation: emendation }
      let(:current_user) { emendation.creator_author }
      let(:command) { described_class.new(emendation, current_user) }

      include_examples "withdraw amendment"
    end
  end
end
