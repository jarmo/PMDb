$(function() {
  $("#content").on('hover', 'a', 
    function(ev) {
      $(this).parent().siblings(".details").slideToggle('fast');
    }
  );

  $(".rescan").on('click', function(ev) {
    var el = $(this);
    el.hide();
    $(".loader").show();
    $.getJSON("/rescan")
      .always(function() {
        $(".loader").hide();
        el.show();
      })
      .done(function(data) {
        render(data);
      })
      .fail(function(jqXHR, textStatus, errorThrown) {
        alert("Got error during request: " + errorThrown);
      });
  });

  render(MOVIES);
});

function render(movies_data) {
  $(".movies").remove();

  var template = $("script[type='text/x-mustache']").html();
  _(movies_data).each(function(movies, dir) {
   var data = {
     dir: dir,
     count: movies.length,
     movies: movies
   };
   $("#content").append(Mustache.to_html(template, data));
  });
}
