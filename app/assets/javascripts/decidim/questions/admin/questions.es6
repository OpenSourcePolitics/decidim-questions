// = require_self
$(document).ready(function () {
  let selectedQuestionsCount = function() {
    return $('.table-list .js-check-all-question:checked').length
  }

  window.selectedQuestionsCountUpdate = function() {
    if(selectedQuestionsCount() == 0){
      $("#js-recategorize-questions-count").text("")
    } else {
      $("#js-recategorize-questions-count").text(selectedQuestionsCount());
    }
  }

  let showBulkActionsButton = function() {
    if(selectedQuestionsCount() > 0){
      $("#js-bulk-actions-button").removeClass('hide');
    }
  }

  let hideBulkActionsButton = function(force = false) {
    if(selectedQuestionsCount() == 0 || force == true){
      $("#js-bulk-actions-button").addClass('hide');
      $("#js-bulk-actions-dropdown").removeClass('is-open');
    }
  }

  window.showOtherActionsButtons = function() {
    $("#js-other-actions-wrapper").removeClass('hide');
  }

  let hideOtherActionsButtons = function() {
    $("#js-other-actions-wrapper").addClass('hide');
  }

  let showRecategorizeQuestionActions = function() {
    $("#js-recategorize-questions-actions").removeClass('hide');
  }

  window.hideRecategorizeQuestionActions = function() {
    return $("#js-recategorize-questions-actions").addClass('hide');
  }

  if ($('#js-form-recategorize-questions').length) {
    window.hideRecategorizeQuestionActions();
    $("#js-bulk-actions-button").addClass('hide');

    $("#js-bulk-actions-recategorize").click(function(e){
      e.preventDefault();

      $('#js-form-recategorize-questions').submit(function(){
        $('.layout-content > .callout-wrapper').html("");
      })

      showRecategorizeQuestionActions();
      hideBulkActionsButton(true);
      hideOtherActionsButtons();
    })

    // select all checkboxes
    $(".js-check-all").change(function() {
      $(".js-check-all-question").prop('checked', $(this).prop("checked"));

      if ($(this).prop("checked")) {
        $(".js-check-all-question").closest('tr').addClass('selected');
        showBulkActionsButton();
      } else {
        $(".js-check-all-question").closest('tr').removeClass('selected');
        hideBulkActionsButton();
      }

      selectedQuestionsCountUpdate();
    });

    // question checkbox change
    $('.table-list').on('change', '.js-check-all-question', function (e) {
      let question_id = $(this).val()
      let checked = $(this).prop("checked")

      // uncheck "select all", if one of the listed checkbox item is unchecked
      if ($(this).prop("checked") === false) {
        $(".js-check-all").prop('checked', false);
      }
      // check "select all" if all checkbox questions are checked
      if ($('.js-check-all-question:checked').length === $('.js-check-all-question').length) {
        $(".js-check-all").prop('checked', true);
        showBulkActionsButton();
      }

      if ($(this).prop("checked")) {
        showBulkActionsButton();
        $(this).closest('tr').addClass('selected');
      } else {
        hideBulkActionsButton();
        $(this).closest('tr').removeClass('selected');
      }

      if ($('.js-check-all-question:checked').length === 0) {
        hideBulkActionsButton();
      }

      $('#js-form-recategorize-questions').find(".js-question-id-"+question_id).prop('checked', checked);
      selectedQuestionsCountUpdate();
    });

    $('#js-cancel-edit-category').on('click', function (e) {
      window.hideRecategorizeQuestionActions()
      showBulkActionsButton();
      showOtherActionsButtons();
    });
  }
});
