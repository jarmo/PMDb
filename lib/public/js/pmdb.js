$(function() {
    $(".ui-icon.ui-icon-plus").click(function() {
        var clicked_icon = $(this);
        var details_panel = $("#details_" + clicked_icon.attr('id').match(/\d+/));
        var hidden_details = details_panel.css('display') == 'none';

        $(".details:visible").slideUp('slow', function() {
            var movie_id = $(this).attr('id').match(/\d+/);
            $("#movie_" + movie_id).addClass('ui-icon-plus').removeClass('ui-icon-minus');
        });

        if (hidden_details) {
            clicked_icon.toggleClass("ui-icon-plus ui-icon-minus");
            details_panel.slideToggle('slow');
        }
    });
});