{
  inputs.flake-utils.url = github:numtide/flake-utils;

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:

      let pkgs = import nixpkgs { inherit system; };

          ## Reads a directory and returns a list of file names.
          readDir' = path: with builtins; attrNames (readDir path);
          readDirSubset = path: suffix: with builtins; with pkgs.lib;
            map (removeSuffix suffix) (filter (hasSuffix suffix) (readDir' path));

          mapToAttrs = f: list: builtins.listToAttrs (map f list);
          mapToAttrs' = f: mapToAttrs (name: { inherit name; value = f name; });

          mapAttrsAsList = f: set: map f (builtins.attrValues set);

          inherit (builtins) mapAttrs concatStringsSep;

          mkDerivation = name: args:
            pkgs.stdenv.mkDerivation ({
              src = self;
              inherit name;

              FONTCONFIG_FILE = pkgs.makeFontsConf { fontDirectories = [
                pkgs.google-fonts ]; };

              buildInputs = with pkgs; [
                inkscape j2cli jq lilypond sassc
                texlive.combined.scheme-full xvfb-run yq-go

                ## Only used for tests:
                firefox imagemagick python310Packages.selenium #implies python310
              ];

              ## Default build phase is to do nothing, not to do `make`.
              buildPhase = "true";

              ## Do not look this derivation up in substitutes, because it is
              ## never going to be there.
              allowSubstitutes = false;
            } // args);

          singleFileInDerivation = der:
            let files = readDir' "${der}/"; in
            if builtins.length files == 1 then
              "${der}/" + builtins.head files
            else
              builtins.throw "derivation is not single-file";

          yaml2json = "yq --output-format json";

          ## ============== [ One Item's Raw Json ] =============== ##

          mkDerivationItemRawJson = kind: slug:
            mkDerivation (kind + "-" + slug + "-raw-json") {
              ## A bit dirty; it should be buildPhase+installPhase.
              installPhase = ''
                mkdir $out
                cat database/${kind}/${slug}.yaml      \
                    | ${yaml2json}                   \
                    | jq '{${kind}:., slug:"${slug}"}' \
                    > $out/${slug}.raw.json
              '';
            };
          mkDerivationDanceRawJson = mkDerivationItemRawJson "dance";
          mkDerivationTuneRawJson = mkDerivationItemRawJson "tune";
          mkDerivationBookRawJson = mkDerivationItemRawJson "book";

          ## ================ [ One Item's Json ] ================= ##

          mkDerivationItemJson = kind: prettyKind: slug: derivationAllRawJson: derivationRawJson:
            mkDerivation (kind + "-" + slug + "-json") {
              installPhase = ''
                mkdir $out
                cat ${derivationRawJson}/${slug}.raw.json \
                    | jq '. + $all + {title:(.${kind}.name + " | ${prettyKind}"), root:".."}' \
                          --argjson all "$(cat ${derivationAllRawJson}/all.raw.json)" \
                    > $out/${slug}.json
              '';
            };
          mkDerivationDanceJson = mkDerivationItemJson "dance" "Dance";
          mkDerivationTuneJson = mkDerivationItemJson "tune" "Tune";
          mkDerivationBookJson = mkDerivationItemJson "book" "Book";

          ## ================== [ Dance's PDF ] =================== ##

          mkDerivationDancePdf = slug: derivationDanceJson:
            mkDerivation ("dance-" + slug + "-pdf") {
              buildPhase = ''
                mkdir _build
                {
                  cat views/tex/preamble.tex
                  j2 views/tex/dance.tex.j2 ${derivationDanceJson}/${slug}.json \
                      --filters views/j2filters.py
                } > _build/${slug}.tex
                {
                  cd _build
                  xelatex -halt-on-error ${slug}
                }
              '';
              installPhase = ''
                install -t $out ${slug}.pdf
              '';
            };

          ## ================ [ One Item's HTML ] ================= ##

          mkDerivationItemHtml = kind: slug: derivationItemJson:
            mkDerivation (kind + "-" + slug + "-html") {
              installPhase = ''
                mkdir $out
                j2 views/html/${kind}.html.j2 \
                    ${derivationItemJson}/${slug}.json \
                    --filters views/j2filters.py \
                    > $out/${slug}.html
              '';
            };
          mkDerivationDanceHtml = mkDerivationItemHtml "dance";
          mkDerivationTuneHtml = mkDerivationItemHtml "tune";
          mkDerivationBookHtml = mkDerivationItemHtml "book";

          ## =================== [ Tune's PDF ] =================== ##

          mkDerivationTunePdf = slug: derivationTuneJson:
            mkDerivation ("tune-" + slug + "-pdf") {
              buildPhase = ''
                mkdir _build
                {
                  cat views/ly/version.ly
                  cat views/ly/repeat-aware.ly
                  cat views/ly/bar-number-in-instrument-name-engraver.ly
                  cat views/ly/beginning-of-line.ly
                  cat views/ly/repeat-volta-fancy.ly
                  cat views/ly/preamble.ly
                  j2 views/ly/tune.ly.j2 \
                      ${derivationTuneJson}/${slug}.json \
                      --filters views/j2filters.py
                } > _build/${slug}.ly
                {
                  cd _build
                  lilypond --loglevel=warning -dno-point-and-click ${slug}
                }
              '';
              installPhase = ''
                install -t $out ${slug}.pdf
              '';
            };

          ## =================== [ Tune's SVG ] =================== ##

          mkDerivationTuneSvg = slug: derivationTuneJson:
            mkDerivation ("tune-" + slug + "-svg") {
              buildPhase = ''
                mkdir _build
                {
                  cat views/ly/version.ly
                  cat views/ly/repeat-aware.ly
                  cat views/ly/bar-number-in-instrument-name-engraver.ly
                  cat views/ly/beginning-of-line.ly
                  cat views/ly/repeat-volta-fancy.ly
                  cat views/ly/preamble.ly
                  cat views/ly/preamble.short.ly
                  j2 views/ly/tune.ly.j2 ${derivationTuneJson}/${slug}.json \
                      --filters views/j2filters.py
                } > _build/${slug}.short.ly
                {
                  cd _build
                  lilypond --loglevel=warning -dno-point-and-click \
                      -dbackend=svg ${slug}.short.ly
                  HOME=$(mktemp -d) xvfb-run inkscape \
                      --batch-process --export-area-drawing --export-plain-svg \
                      --export-filename=${slug}.svg ${slug}.short.svg
                }
              '';
              installPhase = ''
                install -t $out ${slug}.svg
              '';
            };

          ## ====================== [ ... ] ======================= ##

          mkDerivationItemsRawJson = kind: derivationsItemRawJson:
            mkDerivation (kind + "s-raw-json") {
              installPhase =
                if derivationsItemRawJson != [] then
                  ''
                    mkdir $out
                    jq -s 'map({(.slug): (.${kind})}) | .+[{}] | add | {${kind}s:.}' \
                        ${concatStringsSep " " (mapAttrsAsList singleFileInDerivation derivationsItemRawJson)} \
                        > $out/${kind}s.raw.json
                  ''
                else
                  ''
                    mkdir $out
                    echo 'trivial file because no built ${kind}s'
                    jq -n '{${kind}s:[]}' > $out/${kind}s.raw.json
                  '';
            };
          mkDerivationDancesRawJson = mkDerivationItemsRawJson "dance";
          mkDerivationTunesRawJson = mkDerivationItemsRawJson "tune";
          mkDerivationBooksRawJson = mkDerivationItemsRawJson "book";

          ## ====================== [ ... ] ======================= ##

          mkDerivationItemsJson = kind: derivationItemsRawJson:
            mkDerivation (kind + "s-json") {
              installPhase = ''
                mkdir $out
                cat ${derivationItemsRawJson}/${kind}s.raw.json \
                    | jq '. + {root:"."}' \
                    > $out/${kind}s.json
              '';
            };
          mkDerivationDancesJson = mkDerivationItemsJson "dance";
          mkDerivationTunesJson = mkDerivationItemsJson "tune";
          mkDerivationBooksJson = mkDerivationItemsJson "book";

          ## ====================== [ ... ] ======================= ##

          mkDerivationItemsHtml = kind: derivationItemsJson:
            mkDerivation "${kind}s-html" {
              installPhase = ''
                mkdir $out
                j2 views/html/${kind}s.html.j2 \
                    ${derivationItemsJson}/${kind}s.json \
                    --filters views/j2filters.py \
                    > $out/${kind}s.html
              '';
            };
          mkDerivationDancesHtml = mkDerivationItemsHtml "dance";
          mkDerivationTunesHtml = mkDerivationItemsHtml "tune";
          mkDerivationBooksHtml = mkDerivationItemsHtml "book";

          ## ================== [ All.Raw.Json ] ================== ##

          mkDerivationAllRawJson = derivationDancesRawJson: derivationTunesRawJson: derivationBooksRawJson:
            mkDerivation "all-raw-json" {
              installPhase = ''
                mkdir $out
                jq -s '{dances:.[0].dances, tunes:.[1].tunes, books:.[2].books}' \
                    ${derivationDancesRawJson}/dances.raw.json \
                    ${derivationTunesRawJson}/tunes.raw.json \
                    ${derivationBooksRawJson}/books.raw.json \
                    > $out/all.raw.json
              '';
            };

          ## =================== [ Index.Json ] =================== ##

          mkDerivationIndexAndNonScddbJson = kind: derivationAllRawJson:
            mkDerivation (kind + "-json") {
              installPhase = ''
                mkdir $out
                cat ${derivationAllRawJson}/all.raw.json \
                    | jq '. + {root:"."}' \
                    > $out/${kind}.json
              '';
            };
          mkDerivationIndexJson = mkDerivationIndexAndNonScddbJson "index";
          mkDerivationNonScddbJson = mkDerivationIndexAndNonScddbJson "non-scddb";

          ## =================== [ Index.Html ] =================== ##

          mkDerivationIndexAndNonScddbHtml = kind: derivationIndexOrNonScddbJson:
            mkDerivation (kind + "-html") {
              installPhase = ''
                mkdir $out
                j2 views/html/${kind}.html.j2 \
                    ${derivationIndexOrNonScddbJson}/*.json \
                    --filters views/j2filters.py \
                    > $out/${kind}.html
              '';
            };
          mkDerivationIndexHtml = mkDerivationIndexAndNonScddbHtml "index";
          mkDerivationNonScddbHtml = mkDerivationIndexAndNonScddbHtml "non-scddb";

          ## ====================== [ ... ] ======================= ##

          derivationStyleCss = mkDerivation "style-css" {
            installPhase = ''
              mkdir $out
              sassc views/css/style.scss $out/style.css
            '';
          };

          derivationStatic = mkDerivation "static" {
            installPhase = ''
              mkdir $out
              cp views/css/reset.css $out
              cp ${derivationStyleCss}/style.css $out
              cp -R views/static/* $out
            '';
          };

          derivationWebsite =
            let danceSlugs = readDirSubset ./database/dance ".yaml";
                tuneSlugs = readDirSubset ./database/tune ".yaml";
                bookSlugs = readDirSubset ./database/book ".yaml";

                danceSlugs' = mapToAttrs (slug: { name = slug; value = null; }) danceSlugs;
                tuneSlugs' = mapToAttrs (slug: { name = slug; value = null; }) tuneSlugs;
                bookSlugs' = mapToAttrs (slug: { name = slug; value = null; }) bookSlugs;

                danceRawJsons = mapAttrs (slug: _: mkDerivationDanceRawJson slug) danceSlugs';
                tuneRawJsons = mapAttrs (slug: _: mkDerivationTuneRawJson slug) tuneSlugs';
                bookRawJsons = mapAttrs (slug: _: mkDerivationBookRawJson slug) bookSlugs';

                dancesRawJson = mkDerivationDancesRawJson danceRawJsons;
                tunesRawJson = mkDerivationTunesRawJson tuneRawJsons;
                booksRawJson = mkDerivationBooksRawJson bookRawJsons;

                allRawJson = mkDerivationAllRawJson dancesRawJson tunesRawJson booksRawJson;

                danceJsons = mapAttrs (slug: mkDerivationDanceJson slug allRawJson) danceRawJsons;
                tuneJsons = mapAttrs (slug: mkDerivationTuneJson slug allRawJson) tuneRawJsons;
                bookJsons = mapAttrs (slug: mkDerivationBookJson slug allRawJson) bookRawJsons;

                dancePdfs = mapAttrs mkDerivationDancePdf danceJsons;
                danceHtmls = mapAttrs mkDerivationDanceHtml danceJsons;

                tunePdfs = mapAttrs mkDerivationTunePdf tuneJsons;
                tuneSvgs = mapAttrs mkDerivationTuneSvg tuneJsons;
                tuneHtmls = mapAttrs mkDerivationTuneHtml tuneJsons;

                bookHtmls = mapAttrs mkDerivationBookHtml bookJsons;

                dancesJson = mkDerivationDancesJson dancesRawJson;
                tunesJson = mkDerivationTunesJson tunesRawJson;
                booksJson = mkDerivationBooksJson booksRawJson;

                dancesHtml = mkDerivationDancesHtml dancesJson;
                tunesHtml = mkDerivationTunesHtml tunesJson;
                booksHtml = mkDerivationBooksHtml booksJson;

                indexJson = mkDerivationIndexJson allRawJson;
                nonScddbJson = mkDerivationNonScddbJson allRawJson;

                indexHtml = mkDerivationIndexHtml indexJson;
                nonScddbHtml = mkDerivationNonScddbHtml nonScddbJson;

            in mkDerivation "scd-niols-fr" {
              installPhase = ''
                mkdir $out
                cp -R ${derivationStatic}/* $out
                cp ${indexHtml}/* ${nonScddbHtml}/* $out
                cp ${dancesHtml}/* ${tunesHtml}/* ${booksHtml}/* $out
                mkdir $out/dance $out/tune $out/book
              ''     + concatStringsSep "\n" (mapAttrsAsList (danceHtml: "cp ${danceHtml}/* $out/dance/") danceHtmls)
              + "\n" + concatStringsSep "\n" (mapAttrsAsList (dancePdf: "cp ${dancePdf}/* $out/dance/") dancePdfs)
              + "\n" + concatStringsSep "\n" (mapAttrsAsList (tuneHtml: "cp ${tuneHtml}/* $out/tune/") tuneHtmls)
              + "\n" + concatStringsSep "\n" (mapAttrsAsList (tuneSvg: "cp ${tuneSvg}/* $out/tune/") tuneSvgs)
              + "\n" + concatStringsSep "\n" (mapAttrsAsList (tunePdf: "cp ${tunePdf}/* $out/tune/") tunePdfs)
              + "\n" + concatStringsSep "\n" (mapAttrsAsList (bookHtml: "cp ${bookHtml}/* $out/book/") bookHtmls)
              ;
            };
      in {
        packages.default = derivationWebsite;
      }
    );
}
