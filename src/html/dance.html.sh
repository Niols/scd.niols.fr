#!/bin/sh

printf -- '<article>'
printf -- '  <h1>%s</h1>' "$(html name)"
printf -- '  <h2>%s</h2>' "$(html kind)"
printf -- '  <section>'
printf -- '    <p>Devised by %s.</p>' "$(html author)"
printf -- '    <p>See the <a href="%s.pdf">description of the dance</a>.</p>' "$(url slug)"

if exists scddb-id; then
    printf -- '<p>See this dance'
    printf -- '  <a href="https://my.strathspey.org/dd/dance/%s/">' "$(url scddb-id)"
    printf -- '    in the Scottish Country Dance Database</a>.</p>'
fi

printf -- '  </section>'
printf -- '</article>'
