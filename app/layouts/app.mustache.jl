<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    
    <title>Julia Packages</title>
    <link href="css/bootstrap.css" rel="stylesheet">
    <link href="css/flat-ui.css" rel="stylesheet">
    <link rel="stylesheet" href="css/font-awesome.css">
    <link href="css/app.css" rel="stylesheet">
  </head>
  <body>
    <div class="container">
      {{> app/layouts/main_menu.mustache.jl }}
      {{{:yield}}}
      {{> app/layouts/footer.mustache.jl }}
    </div>

    <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>
    <script src="js/bootstrap.js"></script>
    <script src="js/raphael-min.js"></script>
    <script src="js/sparky.js"></script>
    <script src="js/sparklines.js"></script>
  </body>
</html>