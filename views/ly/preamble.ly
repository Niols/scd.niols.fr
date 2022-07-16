%% We like the default staff size, so let's keep it.
%#(set-global-staff-size 20)

\layout {
  indent = 0

  \context {
    \Score

    %% Prevent Lilypond from breaking inside a score without explicit notice.
    \override NonMusicalPaperColumn.line-break-permission = ##f
    \override NonMusicalPaperColumn.page-break-permission = ##f
  }

  \context {
    \Staff

    %% Note head size relatively to the global staff size
    %\override NoteHead.font-size = #-0.6
  }

  \context {
    \ChordNames

    %% Chord name size relatively to the global staff size
    %\override ChordName.font-size = #-0.4
  }
}

\paper {

  %% ============================== [ Fonts ] =============================== %%

  #(define fonts
    (make-pango-font-tree
     "Trebuchet MS"
     "Nimbus Sans"
     "Luxi Mono"
     (/ staff-height pt 20)))

  %% ============================ [ Distances ] ============================= %%

  %% The reference in margins is the book of dances. That book is an A5 book so
  %% they have to be multiplied by sqrt(2) to get these:
  top-margin = 28.303\mm
  bottom-margin = 13.661\mm
  two-sided = ##t
  inner-margin = 19.675\mm
  outer-margin = 14.651\mm

  %% The distance between a (title or top-level) markup and the system that
  %% follows it. Everything is set to 0, and the distance is put in the markups
  %% themselves.
  markup-system-spacing = #'(
    (minimum-distance . 0)
    (padding . 0)
    (basic-distance 0)
    (stretchability . 0)
  )

  %% the distance between the last system of a score and the (title or
  %% top-level) markup that follows it.
  score-markup-spacing = #'(
    (minimum-distance . 12)
    (padding . 2)
    (basic-distance . 12)
    (stretchability . 10)
  )

  %% the distance between the last system of a score and the first system of the
  %% score that follows it, when no (title or top-level) markup exists between
  %% them.
                                %score-system-spacing

  %% The distance between two systems in the same score. One has to be very
  %% careful when playing with that one. In particular, increasing the paddng is
  %% not such a great idea as it will increase the space between systems when
  %% there is an alternative box.
  system-system-spacing = #'(
    (basic-distance . 12)
    (minimum-distance . 8)
    (padding . 1)
    (stretchability . 60)
  )

  %% the distance between two (title or top-level) markups.
  markup-markup-spacing = #'(
    (basic-distance . 1)
    (padding . 0.5)
    (stretchability . 1000000) %% Must be much higher than score-markup-spacing's strechability
  )

  %% the distance from the last system or top-level markup on a page to the
  %% bottom of the printable area (i.e., the top of the bottom margin).
  last-bottom-spacing = #'(
    (minimum-distance . 5)
    (padding . 5)
    (basic-distance . 5)
    (stretchability . 1000)
  )

  %% the distance from the top of the printable area (i.e., the bottom of the
  %% top margin) to the first system on a page, when there is no (title or
  %% top-level) markup between the two.
                                %top-system-spacing

  %% the distance from the top of the printable area (i.e., the bottom of the
  %% top margin) to the first (title or top-level) markup on a page, when there
  %% is no system between the two.
                                %top-markup-spacing

  %% ======================= [ Table of Contents ] ======================== %%

  tocTitleMarkup = \markup {
    \column {
      \vspace #2.7
      \concat {
        \hspace #5
        \abs-fontsize #34.1 "Table of contents"
      }
      \vspace #2.7
    }
  }

  tocTuneMarkup = \markup {
    \column {
      \vspace #0.7
      \abs-fontsize #12.6 \fill-line {
        \fromproperty #'toc:text
        \fromproperty #'toc:page
      }
    }
  }

  tocDanceMarkup = \markup {
    \column {
      \vspace #0.25
      \italic
      \abs-fontsize #10.7 \concat {
        "Dance: "
        \fromproperty #'toc:text
      }
    }
  }











  ragged-right = ##f
  ragged-bottom = ##f
  ragged-last-bottom = ##t

  %% FIXME: works but too late
  #(define-markup-command (auto-toc layout props) ()
    (let ((title (chain-assoc-get 'header:title props)))
     (add-toc-item! 'tocTuneMarkup title)
     #:null))

  #(define-markup-command (score-title-markup layout props) ()

    ;; Auxiliary function taking a list of markup and concatenating
    ;; them with either ',' or 'and' if they are the last one. Useful
    ;; in medleys.
    ;;
    (define (medley-rest-kind-line full-kind)
     (if (null? (cdr full-kind))
      (markup #:concat (#:simple " and " (car full-kind)))
      (markup #:concat (#:simple ", " (car full-kind) (medley-rest-kind-line (cdr full-kind))))))

    ;; Get properties from props.
    ;;
    (let* ((title      (chain-assoc-get 'header:title      props ""))
           (composer   (chain-assoc-get 'header:composer   props ""))
           (dance      (chain-assoc-get 'header:dance      props ""))
           (kind       (chain-assoc-get 'header:kind       props ""))
           (two-chords (chain-assoc-get 'header:two-chords props #f))
           (part       (chain-assoc-get 'header:part       props ""))
           (no-title   (chain-assoc-get 'header:no-title   props #f))
           (ptspace    (chain-assoc-get 'header:post-title-space props 0))

           (null       (markup #:vspace 0))

           (two-chords (if two-chords (markup " — Two Chords") null))
           (dance      (if (eq? dance "") title dance))
           (dance      (if (eq? kind "")
                        (markup #:simple " ")
                        (markup #:concat ("Dance: " #:simple dance " — " #:simple kind two-chords))))

           ;; Add placeholder to all values. The placeholder is an invisible
           ;; unit that will align on the baseline of other texts and that goas
           ;; as high and as low as any text can be. It is useful to avoid that,
           ;; later, LilyPond forgets about text and aligns things randomly.
           (placeholder (markup #:with-color (rgb-color 1 1 1) #:simple "Aj"))
           (title    (markup #:abs-fontsize 25.5 #:combine placeholder title))
           (dance    (markup #:abs-fontsize 12.6 #:combine placeholder dance))
           (part     (markup #:abs-fontsize 12.6 #:combine placeholder part))
           (composer (markup #:abs-fontsize 12.6 #:combine placeholder composer))

           (title    (markup #:center-column (title #:vspace 1 dance)))
         )

     (interpret-markup layout props
      (markup
       #:column (
         (if no-title null (markup #:fill-line (title)))
         (if no-title (markup #:vspace ptspace) (markup #:vspace 5))
         #:fill-line (
           part
           composer
         )
         #:vspace 1
       )
     ))))
  scoreTitleMarkup = \markup \score-title-markup

  oddHeaderMarkup = \markup \null
  evenHeaderMarkup = \markup \null

  oddFooterMarkup = \markup {
    \on-the-fly \not-first-page \fill-line {
      \null \fromproperty #'page:page-number-string
    }
  }
  evenFooterMarkup = \markup {
    \on-the-fly \not-first-page \fill-line {
      \fromproperty #'page:page-number-string \null
    }
  }
}

#(define (markup-or-false? x)
  (or (markup? x) (eq? x #f)))


tocPart = #(define-music-function (parser location text) (markup?)
            (add-toc-item! 'tocPartMarkup text))

tocTune = #(define-music-function (parser location title composer kind) (markup? markup? markup?)
            (add-toc-item! 'tocTuneMarkup (markup #:fill-line (title #:concat (composer #:hspace 5 kind #:hspace 7)))))

tocDance = #(define-music-function (parser location text) (markup?)
             (add-toc-item! 'tocDanceMarkup text))

#(define-markup-command (copyright layout props year composer) (number? string?)
  (interpret-markup layout props
   (markup #:small #:concat (
     #:simple "Copyright © "
     #:simple (number->string year)
     #:simple " "
     #:simple composer
     #:simple "; reproduced with permission; all rights retained by the composer."
   ))))
#(define-markup-command (copyright-noreproduced layout props year composer) (number? string?)
  (interpret-markup layout props
   (markup #:small #:concat (
     #:simple "Copyright © "
     #:simple (number->string year)
     #:simple " "
     #:simple composer
     #:simple "; all rights retained by the composer."
   ))))

move-left =
#(define-music-function (parser location n) (number?)
   #{\once \override ChordName.extra-offset = #`(,(- 0 n) . 0) #})
