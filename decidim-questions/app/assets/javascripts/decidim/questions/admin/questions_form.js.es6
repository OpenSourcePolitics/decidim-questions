$(() => {
  const $form = $(".question_form_admin");

  if ($form.length > 0) {
    const $questionCreatedInMeeting = $form.find("#question_created_in_meeting");
    const $questionMeeting = $form.find("#question_meeting");

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
