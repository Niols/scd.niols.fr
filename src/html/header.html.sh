#!/bin/sh

printf -- '<!DOCTYPE html>'
printf -- '<html lang="en">'
printf -- '<head>'
printf -- '  <title>Niols’s Collection of (Mostly Unpublished) Scottish Country Dances</title>'
printf -- '  <meta charset="utf-8" />'

## Basic style
printf -- '  <link rel="stylesheet" href="%s/reset.css">' "$(url root)"
printf -- '  <link rel="stylesheet" href="https://use.fontawesome.com/releases/v5.8.2/css/all.css" integrity="sha384-oS3vJWv+0UjzBfQzYUhtDYW+Pj2yciDJxpsK1OYPAYjqT085Qq/1cq5FLXAZQ7Ay" crossorigin="anonymous">'

## Style
printf -- '  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">'
printf -- '  <link rel="stylesheet" href="%s/style.css">' "$(url root)"

## DataTables (includes jQuery 3 & Responsive extension)
printf -- '  <link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/1.11.3/css/jquery.dataTables.min.css"/>'
printf -- '  <link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/responsive/2.2.9/css/responsive.dataTables.min.css"/>'
printf -- '  <script type="text/javascript" src="https://code.jquery.com/jquery-3.6.0.min.js"></script>'
printf -- '  <script type="text/javascript" src="https://cdn.datatables.net/1.11.3/js/jquery.dataTables.min.js"></script>'
printf -- '  <script type="text/javascript" src="https://cdn.datatables.net/responsive/2.2.9/js/dataTables.responsive.min.js"></script>'
printf -- '  <script type="text/javascript">'
printf -- '    $(document).ready(function() {'
printf -- "      \$('.datatable').DataTable();" ## /!\
printf -- '    });'
printf -- '  </script>'
printf -- '</head>'
printf -- '<body>'
printf -- '  <header>'
printf -- '    <h1><a href="%s/index.html">Niols’s Collection of' "$(url root)"
printf -- '        (Mostly Unpublished) Scottish Country Dances</a></h1>'
printf -- '  </header>'