#!/bin/sh

printf -- '<article>'
printf -- '  <section>'
printf -- '    <p>See the <a href="dances.html">index of the dances</a>.</p>'
printf -- '    <p>See the <a href="tunes.html">index of the tunes</a>.</p>'
printf -- '  </section>'

printf -- '  <section>'
printf -- '    <table class="datatable responsive nowrap">'
printf -- '      <thead>'
printf -- '        <tr>'
printf -- '          <th>Name</th>'
printf -- '          <th>Type</th>'
printf -- '          <th>Kind</th>'
printf -- '          <th>Deviser</th>'
printf -- '        </tr>'
printf -- '      </thead>'
printf -- '      <tbody>'

iter dances
while next; do
    printf -- '    <tr>'
    printf -- '      <td><a href="dance/%s.html">%s</a></td>' "$(url slug)" "$(html name)"
    printf -- '      <td>Dance</td>'
    printf -- '      <td>%s</td>' "$(html short-kind)"
    printf -- '      <td>%s</td>' "$(html short_author_or_author)"
    printf -- '    </tr>'
done

iter tunes
while next; do
    printf -- '    <tr>'
    printf -- '      <td><a href="tune/%s.html">%s</a></td>' "$(url slug)" "$(html name)"
    printf -- '      <td>Tune</td>'
    printf -- '      <td>%s</td>' "$(html short-kind)"
    printf -- '      <td>%s</td>' "$(html short_author_or_author)"
    printf -- '    </tr>'
done

printf -- '      </tbody>'
printf -- '    </table>'
printf -- '  </section>'
printf -- '</article>'
