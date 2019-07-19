$( document ).ready(function() {
    var ansi_up = new AnsiUp;
    $("code.language-julia").html(ansi_up.ansi_to_html( $("code.language-julia").text() ));
});
