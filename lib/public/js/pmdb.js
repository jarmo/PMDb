$(function() {
  $("#content")
  .on('hover', '.movie a', 
    function(ev) {
      $("#tooltip").remove();
      if (ev.type == "mouseenter")
        showTooltip(ev.pageX, ev.pageY, $(ev.target).closest(".movie").find(".details").html());
    }
  )
  .on('hover', '.movie',
    function(ev) {
      if ($(this).closest(".movie").data("dir") != "temporary")
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

  $(".search input")
    .on('keyup', _.debounce(render, 150))
    .on('keyup', function(ev) {
      if (ev.keyCode != 27) return;
      $(".search input").empty();
      $("body").focus();
      render();
    });

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

  $("#control .add").click(function() {
    $("#add_area").modal({
      opacity:80,
      overlayCss: {backgroundColor:"#ccc"},
      overlayClose:true
    });
  });

  $("#add_area .add").click(function(ev) {
    ev.preventDefault();
    $(this).hide();
    $("#add_area .loader").show();

    $.getJSON("/temporary",
      {list: $("#add_area textarea").val()}
    )
    .always(function() {
      $.modal.close();      
    })
    .done(function(data) {
      MOVIES["temporary"] = data.temporary;
      render();
    })
    .fail(function(jqXHR, textStatus, errorThrown) {
      alert("Got error during request: " + errorThrown)
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

  render();

  function render() {
    $(".movies").remove();

    var template = $("script[type='text/x-mustache']").html();
    _(MOVIES).each(function(movies, dir) {
      var filtered = filter(movies);
      var data = {
        dir: dir,
        count: filtered.length,
        movies: dir == "temporary" ? movies : sort(filtered)
      };
      $("#content").append(Mustache.to_html(template, data));
    });
  }

  function filter(movies) {
    var keywords = $(".search input").val().split(/\s+/);
    var regexps = _(keywords).reduce(function(memo, keyword) {
      return memo.concat(new RegExp(keyword, "i"));
    }, []);
    return _(movies).select(function(movie) {
      return _(regexps).all(function(regexp) {
        return regexp.test(movie.movie.name) || regexp.test(movie.movie.genres);
      });
    });
  }

  function sort(movies) {
    var sortBy = $.cookie('sortBy') || "movie.name";
    var direction = $.cookie('sortDirection') || 1;

    var args = sortBy.split(".");
    var sorted = _(movies).sortBy(function(movie) {
      if (args.length == 2)
        return movie[args[0]][args[1]].toLowerCase();
      else
        return movie[args[0]];
    });

    return direction == 1 ? sorted : _(sorted).reverse();
  }

  function showTooltip(x, y, contents) {
    $('<div id="tooltip">' + contents + '</div>').css({
        top: y + 20,
        left: x + 20
    }).appendTo("body").fadeIn(200);
  }  
});

