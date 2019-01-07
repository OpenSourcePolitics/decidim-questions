# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Amendable
    describe Reject do
      let!(:component) { create(:question_component) }
      let!(:amendable) { create(:question, component: component) }
      let!(:emendation) { create(:question, component: component) }
      let!(:amendment) { create :amendment, amendable: amendable, emendation: emendation }
      let(:command) { described_class.new(form) }

      let(:form) { Decidim::Amendable::RejectForm.from_params(form_params).with_context(form_context) }

      let(:form_params) do
        {
          id: amendment.id
        }
      end

      let(:form_context) do
        {
          current_organization: component.organization,
          current_user: amendable.creator_author,
          current_component: component,
          current_participatory_space: component.participatory_space
        }
      end

      include_examples "reject amendment"
    end
  end
end
