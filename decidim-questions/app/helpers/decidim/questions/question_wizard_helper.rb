# frozen_string_literal: true

module Decidim
  module Questions
    # Simple helpers to handle markup variations for question wizard partials
    module QuestionWizardHelper
      # Returns the css classes used for the question wizard for the desired step
      #
      # step - A symbol of the target step
      # current_step - A symbol of the current step
      #
      # Returns a string with the css classes for the desired step
      def question_wizard_step_classes(step, current_step)
        step_i = step.to_s.split("_").last.to_i
        if step_i == question_wizard_step_number(current_step)
          %(step--active #{step} #{current_step})
        elsif step_i < question_wizard_step_number(current_step)
          %(step--past #{step})
        else
          %()
        end
      end

      # Returns the number of the step
      #
      # step - A symbol of the target step
      def question_wizard_step_number(step)
        step.to_s.split("_").last.to_i
      end

      # Returns the name of the step, translated
      #
      # step - A symbol of the target step
      def question_wizard_step_name(step)
        t("decidim.questions.#{type_of}.wizard_steps.#{step}")
      end

      # Returns the page title of the given step, translated
      #
      # action_name - A string of the rendered action
      def question_wizard_step_title(action_name)
        step_title = case action_name
                     when "create"
                       "new"
                     when "update_draft"
                       "edit_draft"
                     else
                       action_name
                     end

        t("decidim.questions.#{type_of}.#{step_title}.title")
      end

      # Returns the list item of the given step, in html
      #
      # step - A symbol of the target step
      # current_step - A symbol of the current step
      def question_wizard_stepper_step(step, current_step)
        return if step == :step_4 && type_of == :collaborative_drafts
        content_tag(:li, question_wizard_step_name(step), class: question_wizard_step_classes(step, current_step).to_s)
      end

      # Returns the list with all the steps, in html
      #
      # current_step - A symbol of the current step
      def question_wizard_stepper(current_step)
        content_tag :ol, class: "wizard__steps" do
          %(
            #{question_wizard_stepper_step(:step_1, current_step)}
            #{question_wizard_stepper_step(:step_2, current_step)}
            #{question_wizard_stepper_step(:step_3, current_step)}
            #{question_wizard_stepper_step(:step_4, current_step)}
          ).html_safe
        end
      end

      # Returns a string with the current step number and the total steps number
      #
      # step - A symbol of the target step
      def question_wizard_current_step_of(step)
        current_step_num = question_wizard_step_number(step)
        content_tag :span, class: "text-small" do
          concat t(:"decidim.questions.questions.wizard_steps.step_of", current_step_num: current_step_num, total_steps: total_steps)
          concat " ("
          concat content_tag :a, t(:"decidim.questions.questions.wizard_steps.see_steps"), "data-toggle": "steps"
          concat ")"
        end
      end

      # Returns a boolean if the step has a help text defined
      #
      # step - A symbol of the target step
      def question_wizard_step_help_text?(step)
        translated_attribute(component_settings.try("question_wizard_#{step}_help_text")).present?
      end

      # Renders a user_group select field in a form.
      # form - FormBuilder object
      # name - attribute user_group_id
      #
      # Returns nothing.
      def user_group_select_field(form, name)
        selected = @form.user_group_id.presence
        user_groups = Decidim::UserGroups::ManageableUserGroups.for(current_user).verified
        form.select(
          name,
          user_groups.map { |g| [g.name, g.id] },
          selected: selected,
          include_blank: current_user.name
        )
      end

      private

      def total_steps
        case type_of
        when :collaborative_drafts
          3
        when :questions
          4
        else
          4
        end
      end

      def wizard_aside_info_text
        case type_of
        when :collaborative_drafts
          t("info", scope: "decidim.questions.collaborative_drafts.wizard_aside").html_safe
        else
          t("info", scope: "decidim.questions.questions.wizard_aside").html_safe
        end
      end

      def wizard_aside_back_text
        case type_of
        when :collaborative_drafts
          t("back", scope: "decidim.questions.collaborative_drafts.wizard_aside").html_safe
        else
          t("back", scope: "decidim.questions.questions.wizard_aside").html_safe
        end
      end

      def type_of
        if ["Decidim::Questions::CollaborativeDraftForm"].include? @form.class.name
          :collaborative_drafts
        elsif @collaborative_draft.present?
          :collaborative_drafts
        else
          :questions
        end
      end
    end
  end
end
