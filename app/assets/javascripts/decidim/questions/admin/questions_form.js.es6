// = require decidim/tooltip_keep_on_hover

$(() => {
  const $form = $(".question_form_admin");

  if ($form.length > 0) {
    const $questionCreatedInMeeting = $form.find("#question_created_in_meeting");
    const $questionMeeting = $form.find("#question_meeting");

    const states = $('input[name="question[state]"]');
    const current_state = states.filter("[checked]");
    const roles = $('#recipient_role_wrapper');
    const answer = $('#question_answer_wrapper');
    const recipients = $('input[name="question[recipient]"]');
    const currentRecipient = recipients.filter("[checked]");
    const committeeUsers = $('#question_committee_users_wrapper');
    const serviceUsers = $('#question_service_users_wrapper');

    if(states.length) {
      if (current_state.val() !== "evaluating") {
        roles.hide();
        answer.removeClass('hide');
      } else {
        if (currentRecipient.val() === 'committee') {
          committeeUsers.removeClass('hide');
          serviceUsers.addClass('hide');
        } else if (currentRecipient.val() === 'service') {
          committeeUsers.addClass('hide');
          serviceUsers.removeClass('hide');
        } else {
          committeeUsers.addClass('hide');
          serviceUsers.addClass('hide');
        }
      }
      states.change((e) => {
        if ($(e.currentTarget).val() === "evaluating") {
          roles.show();
          answer.addClass('hide');
        } else {
          roles.hide();
          answer.removeClass('hide');
        }
      })

      recipients.change((e) => {
        if ($(e.currentTarget).val() === 'committee') {
          committeeUsers.removeClass('hide');
          serviceUsers.addClass('hide');
        } else if ($(e.currentTarget).val() === 'service') {
          committeeUsers.addClass('hide');
          serviceUsers.removeClass('hide');
        } else {
          committeeUsers.addClass('hide');
          serviceUsers.addClass('hide');
        }
      })
    }

    const toggleDisabledHiddenFields = () => {
      const enabledMeeting = $questionCreatedInMeeting.prop("checked");
      $questionMeeting.find("select").attr("disabled", "disabled");
      $questionMeeting.hide();

      if (enabledMeeting) {
        $questionMeeting.find("select").attr("disabled", !enabledMeeting);
        $questionMeeting.show();
      }
    };

    $questionCreatedInMeeting.on("change", toggleDisabledHiddenFields);
    toggleDisabledHiddenFields();

  }
});
