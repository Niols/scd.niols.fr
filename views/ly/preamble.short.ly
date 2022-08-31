%% This cancels out some changes made in `preamble.ly`. We basically just hide
%% the title and the copyright.

\paper {
  scoreTitleMarkup = \markup \null
}

#(define-markup-command (copyright layout props year composer) (number? string?)
  (interpret-markup layout props (markup)))

#(define-markup-command (copyrightNoYear layout props composer) (string?)
  (interpret-markup layout props (markup)))
