// = require decidim/tooltip_keep_on_hover

$(() => {
  const $form = $('.question_form_admin')
  const states = $('input[name="question[state]"]')
  let currentState = states.filter('[checked]')
  const recipients = $('input[name="question[recipient]"]')
  const currentRecipient = recipients.filter('[checked]')

  const handleState = (state) => {
    const roles = $('#recipient_role_wrapper')
    const answer = $('#question_answer_wrapper')
    currentState = state

    if (state.val() === 'evaluating') {
      roles.show()
      answer.hide()
    } else {
      roles.hide()
      answer.show()
    }

    handleRecipient(currentRecipient, state)
  }
  const handleRecipient = (recipient, state) => {
    const committeeUsers = $('#committee_users_ids_wrapper')
    const serviceUsers = $('#service_users_ids_wrapper')

    if (state.val() !== 'evaluating') {
      committeeUsers.hide()
      serviceUsers.hide()
      return
    }

    if (recipient.val() === 'committee') {
      committeeUsers.show()
      serviceUsers.hide()
    } else if (recipient.val() === 'service') {
      committeeUsers.hide()
      serviceUsers.show()
    } else {
      committeeUsers.hide()
      serviceUsers.hide()
    }
  }

  if ($form.length > 0) {
    const $questionCreatedInMeeting = $form.find('#question_created_in_meeting')
    const $questionMeeting = $form.find('#question_meeting')

    if (states.length) {
      handleState(currentState)
      states.change((e) => handleState($(e.currentTarget)))
      recipients.change((e) => handleRecipient($(e.currentTarget), currentState))
    }

    const toggleDisabledHiddenFields = () => {
      const enabledMeeting = $questionCreatedInMeeting.prop('checked')
      $questionMeeting.find('select').attr('disabled', 'disabled')
      $questionMeeting.hide()

      if (enabledMeeting) {
        $questionMeeting.find('select').attr('disabled', !enabledMeeting)
        $questionMeeting.show()
      }
    }

    $questionCreatedInMeeting.on('change', toggleDisabledHiddenFields)
    toggleDisabledHiddenFields()
  }
})
