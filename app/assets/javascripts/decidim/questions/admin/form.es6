// = require_self
$(document).ready(() => {

  var types = $('input[name="question[question_type]"]')
  var states = $('input[name="question_answer[state]"]')
  var roles = $('#recipient_role_wrapper')

  // Edit form
  if(types.length) {
    console.log('has types');
    if (types.val() != "question") {
      roles.hide();
    }
    types.change((e) => {
      if ($(e.currentTarget).val() == "question") {
        roles.show();
      } else {
        roles.hide();
      }
    })
  }

  // Answer form
  if(states.length) {
    console.log('has states');
    if (states.val() != "evaluating") {
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


});
