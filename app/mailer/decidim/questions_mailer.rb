# frozen_string_literal: true

module Decidim
  class QuestionsMailer < Decidim::ApplicationMailer
    include Decidim::TranslatableAttributes

    helper Decidim::ResourceHelper
    helper_method :question_note_anchor

    def note_created(user, question_note, participatory_space)
      return if user.email.blank?

      with_user(user) do
        @organization = user.organization
        @question_note = question_note
        @question = question_note.question
        @user = user
        @participatory_space = participatory_space
        title_renderer = Decidim::ContentRenderers::HashtagRenderer.new(translated_attribute(@question.title))
        subject = I18n.t("note.created",
                         scope: "decidim.questions_mailer",
                         participatory_space_slug: participatory_space.slug,
                         question_title: title_renderer.render(links: false))
        mail(from: Decidim.config.mailer_sender, to: user.email, subject: subject)
      end
    end

    private

    def question_note_url
      Decidim::EngineRouter.admin_proxy(@question.component).question_question_notes_url(question_id: @question.id)
    end

    def question_note_anchor
      return unless question_note_url

      question_note_url + "#note_#{@question_note.id}"
    end
  end
end
