$(document).ready(function() {
  $(document).on('click', '#reset_link', function() {
    var r = confirm("Would you like to reset the game?");
    if (r === true) {
        window.location = '/reset';
    }

    return false;
  });

  $(document).on('click', '#hit_form button', function() {
    $.ajax({
      type: 'POST',
      url: '/player/hit'
    }).done(function(msg) {
      $('#game').replaceWith(msg);
    });

    return false;
  });

  $(document).on('click', '#stay_form button', function() {
    $.ajax({
      type: 'POST',
      url: '/player/stay'
    }).done(function(msg) {
      $('#game').replaceWith(msg);
    });

    return false;
  });

  $(document).on('click', '#next_card_form button', function() {
    $.ajax({
      type: 'POST',
      url: '/dealer/next'
    }).done(function(msg) {
      $('#game').replaceWith(msg);
    });

    return false;
  });
});