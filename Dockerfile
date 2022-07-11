FROM debian:11

## Install dependencies
RUN apt-get update -y
RUN DEBIAN_FRONTEND=noninteractive apt-get install -yq \
        make jq \
        texlive-xetex texlive-extra-utils latexmk

## Add group and user `builder`
RUN addgroup builder \
    && adduser --system --shell /bin/false --disabled-password \
               --home /wd --ingroup builder builder \
    && chown -R builder:builder /wd
USER builder
WORKDIR /wd

## Copy assets and setup Trebuchet MS
COPY --chown=builder:builder src/assets/fonts \
                             /wd/.local/share/fonts/
