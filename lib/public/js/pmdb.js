$(function() {
  $("#content").on('hover', 'a', 
    function(ev) {
      $(this).parent().siblings(".details").slideToggle('fast');
    }
  );

  render();
});

function render() {
  var template = $("script[type='text/x-mustache']").html();
  _(MOVIES).each(function(movies, dir) {
   var data = {
     dir: dir,
     count: movies.length,
     movies: movies
   };
   $("#content").append(Mustache.to_html(template, data));
  });
}
