$(function() {
  $("#content")
  .on('hover', '.movie a', 
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
        MOVIES[el.data("dir")] = _(MOVIES[el.data("dir")]).reject(function(movie) {return movie.path == el.data("path")});
        el.remove();
      })
      .fail(function(jqXHR, textStatus, errorThrown) {
        alert("Got error during request: " + errorThrown)
      });
    }
  );

  $(".search input").on('keyup', _.debounce(function() {
    var regexp = new RegExp($(this).val(), "i");
    var filtered = _(MOVIES).reduce(function(memo, movies, dir) {
      memo[dir] = _(movies).select(function(movie) {
        return regexp.test(movie.imdb.name) || regexp.test(movie.imdb.genres);
      });

      return memo;
    }, {});

    render(filtered);
  }, 100));

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
        MOVIES = data;
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
