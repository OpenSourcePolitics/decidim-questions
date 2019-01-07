# frozen_string_literal: true

require "spec_helper"

describe "Fingerprint question", type: :system do
  let(:manifest_name) { "questions" }

  let!(:fingerprintable) do
    create(:question, component: component)
  end

  include_examples "fingerprint"
end
