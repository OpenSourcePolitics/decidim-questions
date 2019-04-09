module Decidim
  class QuestionsMailer < Decidim::ApplicationMailer
    helper Decidim::ResourceHelper
    helper_method :questions_url

    def note_created(user, question_note)
      with_user(user) do
        @organization = user.organization
        @question_note = question_note
        @question = question_note.question
        @user = user
        subject = I18n.t("note.created", scope: "decidim.questions_mailer")
        mail(from: Decidim.config.mailer_sender, to: user.email, subject: subject)
      end
    end

    private

    def questions_url
      Decidim::EngineRouter.admin_proxy(@question.component).question_question_notes_path(question_id: @question.id)
    end
  end
end