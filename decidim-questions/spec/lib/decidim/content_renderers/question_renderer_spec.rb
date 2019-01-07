# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ContentRenderers
    describe QuestionRenderer do
      let!(:renderer) { Decidim::ContentRenderers::QuestionRenderer.new(content) }

      describe "on parse" do
        subject { renderer.render }

        context "when content is nil" do
          let(:content) { nil }

          it { is_expected.to eq("") }
        end

        context "when content is empty string" do
          let(:content) { "" }

          it { is_expected.to eq("") }
        end

        context "when conent has no gids" do
          let(:content) { "whatever content with @mentions and #hashes but no gids." }

          it { is_expected.to eq(content) }
        end

        context "when content has one gid" do
          let(:question) { create(:question) }
          let(:content) do
            "This content references question #{question.to_global_id}."
          end

          it { is_expected.to eq("This content references question #{question_as_html_link(question)}.") }
        end

        context "when content has many links" do
          let(:question_1) { create(:question) }
          let(:question_2) { create(:question) }
          let(:question_3) { create(:question) }
          let(:content) do
            gid1 = question_1.to_global_id
            gid2 = question_2.to_global_id
            gid3 = question_3.to_global_id
            "This content references the following questions: #{gid1}, #{gid2} and #{gid3}. Great?I like them!"
          end

          it { is_expected.to eq("This content references the following questions: #{question_as_html_link(question_1)}, #{question_as_html_link(question_2)} and #{question_as_html_link(question_3)}. Great?I like them!") }
        end
      end

      def question_url(question)
        Decidim::ResourceLocatorPresenter.new(question).path
      end

      def question_as_html_link(question)
        href = question_url(question)
        title = question.title
        %(<a href="#{href}">#{title}</a>)
      end
    end
  end
end
