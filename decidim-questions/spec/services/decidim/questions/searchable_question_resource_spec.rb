# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe Search do
    subject { described_class.new(params) }

    let(:current_component) { create :question_component, manifest_name: "questions" }
    let(:organization) { current_component.organization }
    let(:scope1) { create :scope, organization: organization }
    let(:author) { create(:user, organization: organization) }
    let!(:question) do
      create(
        :question,
        :draft,
        component: current_component,
        scope: scope1,
        title: "Nulla TestCheck accumsan tincidunt.",
        body: "Nulla TestCheck accumsan tincidunt description Ow!",
        users: [author]
      )
    end

    describe "Indexing of questions" do
      context "when implementing Searchable" do
        context "when on create" do
          context "when questions are NOT official" do
            let(:question2) do
              create(:question, component: current_component)
            end

            it "does not index a SearchableResource after Question creation when it is not official" do
              searchables = SearchableResource.where(resource_type: question.class.name, resource_id: [question.id, question2.id])
              expect(searchables).to be_empty
            end
          end

          context "when questions ARE official" do
            let(:author) { organization }

            before do
              question.update(published_at: Time.current)
            end

            it "does indexes a SearchableResource after Question creation when it is official" do
              organization.available_locales.each do |locale|
                searchable = SearchableResource.find_by(resource_type: question.class.name, resource_id: question.id, locale: locale)
                expect_searchable_resource_to_correspond_to_question(searchable, question, locale)
              end
            end
          end
        end

        context "when on update" do
          context "when it is NOT published" do
            it "does not index a SearchableResource when Question changes but is not published" do
              searchables = SearchableResource.where(resource_type: question.class.name, resource_id: question.id)
              expect(searchables).to be_empty
            end
          end

          context "when it IS published" do
            before do
              question.update published_at: Time.current
            end

            it "inserts a SearchableResource after Question is published" do
              organization.available_locales.each do |locale|
                searchable = SearchableResource.find_by(resource_type: question.class.name, resource_id: question.id, locale: locale)
                expect_searchable_resource_to_correspond_to_question(searchable, question, locale)
              end
            end

            it "updates the associated SearchableResource after published Question update" do
              searchable = SearchableResource.find_by(resource_type: question.class.name, resource_id: question.id)
              created_at = searchable.created_at
              updated_title = "Brand new title"
              question.update(title: updated_title)

              question.save!
              searchable.reload

              organization.available_locales.each do |locale|
                searchable = SearchableResource.find_by(resource_type: question.class.name, resource_id: question.id, locale: locale)
                expect(searchable.content_a).to eq updated_title
                expect(searchable.updated_at).to be > created_at
              end
            end

            it "removes tha associated SearchableResource after unpublishing a published Question on update" do
              question.update(published_at: nil)

              searchables = SearchableResource.where(resource_type: question.class.name, resource_id: question.id)
              expect(searchables).to be_empty
            end
          end
        end

        context "when on destroy" do
          it "destroys the associated SearchableResource after Question destroy" do
            question.destroy

            searchables = SearchableResource.where(resource_type: question.class.name, resource_id: question.id)

            expect(searchables.any?).to be false
          end
        end
      end
    end

    describe "Search" do
      context "when searching by Question resource_type" do
        let!(:question2) do
          create(
            :question,
            component: current_component,
            scope: scope1,
            title: Decidim::Faker.name,
            body: "Chewie, I'll be waiting for your signal. Take care, you two. May the Force be with you. Ow!"
          )
        end

        before do
          question.update(published_at: Time.current)
          question2.update(published_at: Time.current)
        end

        it "returns Question results" do
          Decidim::Search.call("Ow", organization, resource_type: question.class.name) do
            on(:ok) do |results_by_type|
              results = results_by_type[question.class.name]
              expect(results[:count]).to eq 2
              expect(results[:results]).to match_array [question, question2]
            end
            on(:invalid) { raise("Should not happen") }
          end
        end

        it "allows searching by prefix characters" do
          Decidim::Search.call("wait", organization, resource_type: question.class.name) do
            on(:ok) do |results_by_type|
              results = results_by_type[question.class.name]
              expect(results[:count]).to eq 1
              expect(results[:results]).to eq [question2]
            end
            on(:invalid) { raise("Should not happen") }
          end
        end
      end
    end

    private

    def expect_searchable_resource_to_correspond_to_question(searchable, question, locale)
      attrs = searchable.attributes.clone
      attrs.delete("id")
      attrs.delete("created_at")
      attrs.delete("updated_at")
      expect(attrs.delete("datetime").to_s(:short)).to eq(question.published_at.to_s(:short))
      expect(attrs).to eq(expected_searchable_resource_attrs(question, locale))
    end

    def expected_searchable_resource_attrs(question, locale)
      {
        "content_a" => question.title,
        "content_b" => "",
        "content_c" => "",
        "content_d" => question.body,
        "locale" => locale,

        "decidim_organization_id" => question.component.organization.id,
        "decidim_participatory_space_id" => current_component.participatory_space_id,
        "decidim_participatory_space_type" => current_component.participatory_space_type,
        "decidim_scope_id" => question.decidim_scope_id,
        "resource_id" => question.id,
        "resource_type" => "Decidim::Questions::Question"
      }
    end
  end
end
