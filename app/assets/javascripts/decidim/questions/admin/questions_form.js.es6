// = require decidim/tooltip_keep_on_hover

$(() => {
  const $form = $(".question_form_admin");

  if ($form.length > 0) {
    const $questionCreatedInMeeting = $form.find("#question_created_in_meeting");
    const $questionMeeting = $form.find("#question_meeting");

    const states = $('input[name="question[state]"]')
    const current_state = states.filter("[checked]")
    const roles = $('#recipient_role_wrapper')

    if(states.length) {
      if (current_state.val() != "evaluating") {
        roles.hide();
      }
      states.change((e) => {
        if ($(e.currentTarget).val() == "evaluating") {
          roles.show();
        } else {
          roles.hide();
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
