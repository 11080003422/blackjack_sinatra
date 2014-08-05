$(document).ready(function() {
  $(document).on('click', '#reset_link', function() {
    var r = confirm("Would you like to reset the game?");
    if (r === true) {
        window.location = '/reset';
    }

    return false;
  });
});