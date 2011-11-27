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

  $(".search input").on('keyup', _.debounce(render, 150));

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
        render();
      })
      .fail(function(jqXHR, textStatus, errorThrown) {
        alert("Got error during request: " + errorThrown);
      });
  });

  $("#control a").on('click', function(ev) {
    ev.preventDefault();
    var sortBy = $(this).data('sort');
    var current = $.cookie('sortBy');
    var direction = $.cookie('sortDirection');
    if (sortBy == current && direction) direction *= -1;
    else direction = 1;

    $.cookie('sortBy', sortBy);
    $.cookie('sortDirection', direction);

    render();
  });

  $(".search input").focus();
  render();

  function render() {
    $(".movies").remove();

    var template = $("script[type='text/x-mustache']").html();
    _(MOVIES).each(function(movies, dir) {
      var filtered = filter(movies);
      var data = {
        dir: dir,
        count: filtered.length,
        movies: sort(filtered)
      };
      $("#content").append(Mustache.to_html(template, data));
    });
  }

  function filter(movies) {
    var regexp = new RegExp($(".search input").val(), "i");
    return _(movies).select(function(movie) {
      return regexp.test(movie.imdb.name) || regexp.test(movie.imdb.genres);
    });
  }

  function sort(movies) {
    var sortBy = $.cookie('sortBy') || "imdb.name";
    var direction = $.cookie('sortDirection') || 1;

    var args = sortBy.split(".");
    var sorted = _(movies).sortBy(function(movie) {
      if (args.length == 2)
        return movie[args[0]][args[1]];
      else
        return movie[args[0]];
    });

    return direction == 1 ? sorted : _(sorted).reverse();
  }
});

