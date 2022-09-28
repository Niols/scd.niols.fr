FROM debian:11

## Install dependencies.
RUN apt-get update -y
RUN apt-get install -yq make wget xvfb firefox-esr imagemagick

## Install `yq`. We use the i386 version because that's what Debian 11 in Docker
## seems to be.
RUN wget https://github.com/mikefarah/yq/releases/download/v4.25.3/yq_linux_386 \
        -qO /usr/local/bin/yq
RUN chmod +x /usr/local/bin/yq

## Ready a directory to get files from the outside.
RUN mkdir /src

## Add group and user `tester`.
RUN addgroup tester \
    && adduser --system --shell /bin/false --disabled-password \
               --home /wd --ingroup tester tester \
    && chown -R tester:tester /wd
USER tester
WORKDIR /wd

## Copy assets and setup Trebuchet MS
COPY --chown=tester:tester ./assets/fonts /wd/.local/share/fonts/
