$(function() {
  $('[data-toggle="tooltip"]').tooltip(); 
});

$(function() {
  sparky.presets.set("big", {
    width: 450,
    height: 100,
    padding: 10,
    line_stroke: "red",
    line_stroke_width: 2,
    dot_radius: function(d, i) {
        return this.last ? 5 : 0;
    },
    dot_fill: "red",
    dot_stroke: "white",
    dot_stroke_width: 1
    });

    sparky.presets.set("rainbow", {
      padding: 5,
      line_stroke: "none",
      dot_radius: function() {
          return 1.5 + Math.random() * 3.5;
      },
      dot_fill: function() {
          var r = (~~(Math.random() * 16)).toString(16),
              g = (~~(Math.random() * 16)).toString(16),
              b = (~~(Math.random() * 16)).toString(16);
          return ["#", r, g, b].join("");
      }
    });

    var sparks = document.querySelectorAll(".sparkline"),
        len = sparks.length;
    for (var i = 0; i < len; i++) {
        var el = sparks[i],
            data = sparky.parse.numbers(el.getAttribute("data-points")),
            preset = sparky.presets.get(el.getAttribute("data-preset")),
            options = sparky.util.getElementOptions(el, preset);
        sparky.sparkline(el, data, options);
    }
});