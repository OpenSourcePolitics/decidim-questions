$(() => {
  window.DecidimQuestions = window.DecidimQuestions || {};

  window.DecidimQuestions.bindQuestionAddress = () => {
    const $checkbox = $("input:checkbox[name$='[has_address]']");
    const $addressInput = $("#address_input");

    if ($checkbox.length > 0) {
      const toggleInput = () => {
        if ($checkbox[0].checked) {
          $addressInput.show();
        } else {
          $addressInput.hide();
        }
      }
      toggleInput();
      $checkbox.on("change", toggleInput);
    }
  };

  window.DecidimQuestions.bindQuestionAddress();
});
