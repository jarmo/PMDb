$(function() {
  $("#content").on('hover', 'a', 
    function(ev) {
      $(this).parent().siblings(".details").slideToggle('fast');
    }
  );
});
