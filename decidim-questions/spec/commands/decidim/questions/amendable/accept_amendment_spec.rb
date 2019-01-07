# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Amendable
    describe Accept do
      let!(:component) { create(:question_component) }
      let!(:amendable) { create(:question, component: component) }
      let!(:emendation) { create(:question, component: component) }
      let!(:amendment) { create :amendment, amendable: amendable, emendation: emendation }
      let(:command) { described_class.new(form) }

      let(:emendation_fields) do
        {
          title: emendation.title,
          body: emendation.body
        }
      end

      let(:form_params) do
        {
          id: amendment.id,
          emendation_fields: emendation_fields
        }
      end

      let(:form) { Decidim::Amendable::ReviewForm.from_params(form_params) }

      include_examples "accept amendment"
    end
  end
end
