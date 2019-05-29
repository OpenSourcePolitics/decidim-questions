# frozen_string_literal: true

require "spec_helper"

module Decidim
  module Questions
    describe MarkdownToQuestions do
      def should_parse_and_produce_questions(num_questions)
        questions = Decidim::Questions::Question.where(component: component)
        expect { parser.parse(document) }.to change { questions.count }.by(num_questions)
        questions
      end

      def should_have_expected_states(question)
        expect(question.draft?).to be true
        expect(question.official?).to be true
      end

      def question_should_conform(section_level, title, body)
        question = Decidim::Questions::Question.where(component: component).last
        expect(question.participatory_text_level).to eq(Decidim::Questions::ParticipatoryTextSection::LEVELS[section_level])
        expect(question.title).to eq(title)
        expect(question.body).to eq(body)
      end

      let!(:component) { create(:question_component) }
      let(:parser) { MarkdownToQuestions.new(component, create(:user)) }
      let(:items) { [] }
      let(:document) do
        items.join("\n")
      end

      describe "titles create sections and sub-sections" do
        context "with titles of level 1" do
          let(:title) { ::Faker::Book.title }

          before do
            items << "# #{title}\n"
          end

          it "create sections" do
            should_parse_and_produce_questions(1)

            question = Question.last
            expect(question.title).to eq(title)
            expect(question.body).to eq(title)
            expect(question.position).to eq(1)
            expect(question.participatory_text_level).to eq(ParticipatoryTextSection::LEVELS[:section])
            should_have_expected_states(question)
          end
        end

        context "with titles of deeper levels" do
          let(:titles) { (0...5).collect { |idx| "#{idx}-#{::Faker::Book.title}" } }

          before do
            titles.each_with_index { |title, idx| items << "#{"#" * (2 + idx)} #{title}\n" }
          end

          it "create sub-sections" do
            expected_pos = 1

            questions = should_parse_and_produce_questions(5)

            questions.order(:position).each_with_index do |question, idx|
              expect(question.title).to eq(titles[idx])
              expect(question.body).to eq(titles[idx])
              expect(question.position).to eq(expected_pos)
              expected_pos += 1
              expect(question.participatory_text_level).to eq("sub-section")
              should_have_expected_states(question)
            end
          end
        end
      end

      describe "paragraphs create articles" do
        let(:paragraph) { ::Faker::Lorem.paragraph }

        before do
          items << "#{paragraph}\n"
        end

        it "produces a question like an article" do
          should_parse_and_produce_questions(1)

          question = Question.last
          # question titled with its numbering (position)
          expect(question.title).to eq("1")
          expect(question.body).to eq(paragraph)
          expect(question.position).to eq(1)
          expect(question.participatory_text_level).to eq(ParticipatoryTextSection::LEVELS[:article])
          should_have_expected_states(question)
        end
      end

      describe "links are parsed" do
        let(:text_w_link) { %[This text links to [Meta Decidim](https://meta.decidim.org "Community's meeting point").] }

        before do
          items << "#{text_w_link}\n"
        end

        it "contains the link as an html anchor" do
          should_parse_and_produce_questions(1)

          question = Question.last
          # question titled with its numbering (position)
          # the paragraph and question's body
          expect(question.title).to eq("1")
          paragraph = %q(This text links to <a href="https://meta.decidim.org" title="Community's meeting point">Meta Decidim</a>.)
          expect(question.body).to eq(paragraph)
          expect(question.position).to eq(1)
          expect(question.participatory_text_level).to eq(ParticipatoryTextSection::LEVELS[:article])
          should_have_expected_states(question)
        end
      end

      describe "images are parsed" do
        let(:image) { %{Text with ![Important image for Decidim](https://meta.decidim.org/assets/decidim/decidim-logo-1f39092fb3e41d23936dc8aeadd054e2119807dccf3c395de88637e4187f0a3f.svg "Img title").} }

        before do
          items << "#{image}\n"
        end

        it "contains the image as an html img tag" do
          should_parse_and_produce_questions(1)

          question = Question.last
          expect(question.title).to eq("1")
          paragraph = 'Text with <img src="https://meta.decidim.org/assets/decidim/decidim-logo-1f39092fb3e41d23936dc8aeadd054e2119807dccf3c395de88637e4187f0a3f.svg" alt="Important image for Decidim" title="Img title"/>.'
          expect(question.body).to eq(paragraph)
          expect(question.position).to eq(1)
          expect(question.participatory_text_level).to eq(ParticipatoryTextSection::LEVELS[:article])
          should_have_expected_states(question)
        end
      end

      describe "lists as a whole" do
        context "when unordered" do
          let(:list) do
            <<~EOLIST
              - one
              - two
              - three
            EOLIST
          end

          before do
            items << "#{list}\n"
          end

          it "are articles" do
            should_parse_and_produce_questions(1)
            question_should_conform(:article, "1", list)
          end
        end

        context "when ordered" do
          let(:list) do
            <<~EOLIST
              1. one
              2. two
              3. three
            EOLIST
          end

          before do
            items << "#{list}\n"
          end

          it "are articles" do
            should_parse_and_produce_questions(1)
            question_should_conform(:article, "1", list)
          end
        end
      end
    end
  end
end
