FROM debian:11

## Install most dependencies. `wget` is only needed for `yq`.
RUN apt-get update -y
RUN DEBIAN_FRONTEND=noninteractive apt-get install -yq \
        make jq sassc wget lilypond inkscape \
        texlive-xetex texlive-extra-utils latexmk

## Install `yq`. We use the i386 version because that's what Debian 11 in Docker
## seems to be.
RUN wget https://github.com/mikefarah/yq/releases/download/v4.25.3/yq_linux_386 \
        -qO /usr/local/bin/yq
RUN chmod +x /usr/local/bin/yq

## Add group and user `builder`
RUN addgroup builder \
    && adduser --system --shell /bin/false --disabled-password \
               --home /wd --ingroup builder builder \
    && chown -R builder:builder /wd
USER builder
WORKDIR /wd

## Copy assets and setup Trebuchet MS
COPY --chown=builder:builder ./assets/fonts \
                             /wd/.local/share/fonts/
