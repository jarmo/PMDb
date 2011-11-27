$(function() {
  $("#content")
  .on('hover', 'a', 
    function() {
      $(this).parent().siblings(".details").slideToggle('fast');
    }
  )
  .on('hover', '.movie',
    function(ev) {
      $(this).find('.remove').toggle(ev.type == "mouseenter");
    }
  )
  .on('click', '.remove',
    function() {
      var el = $(this).hide().closest(".movie");
      $.ajax("/remove", {
        type: "POST",
        data: {dir: el.data("dir"), path: el.data("path")}
      })
      .done(function() {
        var counter = el.closest(".movies").find(".count");
        counter.html(Number(counter.html() - 1));
        el.remove();
      })
      .fail(function(jqXHR, textStatus, errorThrown) {
        alert("Got error during request: " + errorThrown)
      });
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
