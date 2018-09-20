// = require_self
$(document).ready(() => {

  var types = $('input[name="question[question_type]"]')
  var states = $('input[name="question_answer[state]"]')
  var current_state = states.filter("[checked]")
  var roles = $('#recipient_role_wrapper')
  var current_role = roles.find('input[name="question_answer[recipient_role]"][checked]')
  var answer_body = $('#answer_body')

  // Edit form
  if(types.length) {
    // console.log('has types');
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
    if (current_state.val() != "evaluating") {
      roles.hide();
    }
    // else if (current_role.val() != "service") {
    //
    // }
    // console.log(answer_body.find('.editor > input[type="hidden"]').empty());
    // console.log('---');
    //
    // if ( answer_body.find('.editor > input[type="hidden"]').empty() && (current_state.val() != "rejected") ) {
    //   answer_body.hide();
    // }
    states.change((e) => {
      if ($(e.currentTarget).val() == "evaluating") {
        roles.show();
      } else {
        roles.hide();
      }
      // if ($(e.currentTarget).val() == "rejected") {
      //   answer_body.show();
      // } else {
      //   answer_body.hide();
      // }
    })
  }


});
