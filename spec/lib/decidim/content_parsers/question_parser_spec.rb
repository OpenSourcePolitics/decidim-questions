# frozen_string_literal: true

require "spec_helper"

module Decidim
  module ContentParsers
    describe QuestionParser do
      let(:organization) { create(:organization) }
      let(:component) { create(:question_component, organization: organization) }
      let(:context) { { current_organization: organization } }
      let!(:parser) { Decidim::ContentParsers::QuestionParser.new(content, context) }

      describe "ContentParser#parse is invoked" do
        let(:content) { "" }

        it "must call QuestionParser.parse" do
          expect(described_class).to receive(:new).with(content, context).and_return(parser)

          result = Decidim::ContentProcessor.parse(content, context)

          expect(result.rewrite).to eq ""
          expect(result.metadata[:question].class).to eq Decidim::ContentParsers::QuestionParser::Metadata
        end
      end

      describe "on parse" do
        subject { parser.rewrite }

        context "when content is nil" do
          let(:content) { nil }

          it { is_expected.to eq("") }
          it "has empty metadata" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::QuestionParser::Metadata)
            expect(parser.metadata.linked_questions).to eq([])
          end
        end

        context "when content is empty string" do
          let(:content) { "" }

          it { is_expected.to eq("") }
          it "has empty metadata" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::QuestionParser::Metadata)
            expect(parser.metadata.linked_questions).to eq([])
          end
        end

        context "when conent has no links" do
          let(:content) { "whatever content with @mentions and #hashes but no links." }

          it { is_expected.to eq(content) }
          it "has empty metadata" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::QuestionParser::Metadata)
            expect(parser.metadata.linked_questions).to eq([])
          end
        end

        context "when content links to an organization different from current" do
          let(:question) { create(:question, component: component) }
          let(:external_question) { create(:question, component: create(:question_component, organization: create(:organization))) }
          let(:content) do
            url = question_url(external_question)
            "This content references question #{url}."
          end

          it "does not recognize the question" do
            subject
            expect(parser.metadata.linked_questions).to eq([])
          end
        end

        context "when content has one link" do
          let(:question) { create(:question, component: component) }
          let(:content) do
            url = question_url(question)
            "This content references question #{url}."
          end

          it { is_expected.to eq("This content references question #{question.to_global_id}.") }
          it "has metadata with the question" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::QuestionParser::Metadata)
            expect(parser.metadata.linked_questions).to eq([question.id])
          end
        end

        context "when content has one link that is a simple domain" do
          let(:link) { "aaa:bbb" }
          let(:content) do
            "This content contains #{link} which is not a URI."
          end

          it { is_expected.to eq(content) }
          it "has metadata with the question" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::QuestionParser::Metadata)
            expect(parser.metadata.linked_questions).to be_empty
          end
        end

        context "when content has many links" do
          let(:question1) { create(:question, component: component) }
          let(:question2) { create(:question, component: component) }
          let(:question3) { create(:question, component: component) }
          let(:content) do
            url1 = question_url(question1)
            url2 = question_url(question2)
            url3 = question_url(question3)
            "This content references the following questions: #{url1}, #{url2} and #{url3}. Great?I like them!"
          end

          it { is_expected.to eq("This content references the following questions: #{question1.to_global_id}, #{question2.to_global_id} and #{question3.to_global_id}. Great?I like them!") }
          it "has metadata with all linked questions" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::QuestionParser::Metadata)
            expect(parser.metadata.linked_questions).to eq([question1.id, question2.id, question3.id])
          end
        end

        context "when content has a link that is not in a questions component" do
          let(:question) { create(:question, component: component) }
          let(:content) do
            url = question_url(question).sub(%r{/questions/}, "/something-else/")
            "This content references a non-question with same ID as a question #{url}."
          end

          it { is_expected.to eq(content) }
          it "has metadata with no reference to the question" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::QuestionParser::Metadata)
            expect(parser.metadata.linked_questions).to be_empty
          end
        end

        context "when content has words similar to links but not links" do
          let(:similars) do
            %w(AA:aaa AA:sss aa:aaa aa:sss aaa:sss aaaa:sss aa:ssss aaa:ssss)
          end
          let(:content) do
            "This content has similars to links: #{similars.join}. Great! Now are not treated as links"
          end

          it { is_expected.to eq(content) }
          it "has empty metadata" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::QuestionParser::Metadata)
            expect(parser.metadata.linked_questions).to be_empty
          end
        end

        context "when question in content does not exist" do
          let(:question) { create(:question, component: component) }
          let(:url) { question_url(question) }
          let(:content) do
            question.destroy
            "This content references question #{url}."
          end

          it { is_expected.to eq("This content references question #{url}.") }
          it "has empty metadata" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::QuestionParser::Metadata)
            expect(parser.metadata.linked_questions).to eq([])
          end
        end

        context "when question is linked via ID" do
          let(:question) { create(:question, component: component) }
          let(:content) { "This content references question ~#{question.id}." }

          it { is_expected.to eq("This content references question #{question.to_global_id}.") }
          it "has metadata with the question" do
            subject
            expect(parser.metadata).to be_a(Decidim::ContentParsers::QuestionParser::Metadata)
            expect(parser.metadata.linked_questions).to eq([question.id])
          end
        end
      end

      def question_url(question)
        Decidim::ResourceLocatorPresenter.new(question).url
      end
    end
  end
end
