#!/bin/sh

printf -- '<article>'
printf -- '  <h1>%s</h1>' "$(html name)"
printf -- '  <h2>%s</h2>' "$(html kind)"

printf -- '  <section>'
printf -- '    <p>Composed by %s.</p>' "$(html author)"

if exists scddb-id; then
    printf -- '<p>See this tune'
    printf -- '  <a href="https://my.strathspey.org/dd/tune/%s/">' "$(url scddb-id)"
    printf -- '    on the Scottish Country Dance Database</a>.</p>'
fi

printf -- '  </section>'
printf -- '</article>'
