#!/bin/sh

printf '<article>'
printf   '<h1>All Dances</h1>'
printf   '<section>'
printf     '<table class="datatable responsive nowrap">'
printf       '<thead>'
printf         '<tr>'
printf           '<th>Name</th>'
printf           '<th>Kind</th>'
printf           '<th>Deviser</th>'
printf         '</tr>'
printf       '</thead>'
printf       '<tbody>'

iter dances
while next; do
    printf     '<tr>'
    printf       '<td><a href="dance/%s.html">%s</a></td>' "$(url slug)" "$(html name)"
    printf       '<td>%s</td>' "$(html short-kind)"
    printf       '<td>%s</td>' "$(html short_author_or_author)"
    printf     '</tr>'
done

printf       '</tbody>'
printf     '</table>'
printf   '</section>'
printf '</article>'
