# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Amendable
    describe AmendmentAcceptedEvent do
      let!(:component) { create(:question_component) }
      let!(:amendable) { create(:question, component: component) }
      let!(:emendation) { create(:question, component: component) }
      let!(:amendment) { create :amendment, amendable: amendable, emendation: emendation }
      let(:amendable_type) { "question" }

      include_examples "amendment accepted event"
    end
  end
end
