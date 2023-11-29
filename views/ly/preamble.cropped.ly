%% This cancels out a lot of defaults and some changes made in `preamble.ly`.

\paper {
  %% Hide the title
  scoreTitleMarkup = \markup \null

  %% Make the page as big as its content
  page-breaking = #ly:one-page-breaking

  %% Remove horizontal margins
  two-sided = #f
  left-margin = 0
  right-margin = 0

  %% Remove all vertical margins
  top-margin = 0
  bottom-margin = 0

  %% Remove most other flexible vertical spacing
  score-system-spacing = 0
  markup-system-spacing = 0
  score-markup-spacing = 0
  markup-markup-spacing = 0
  top-system-spacing = 0
  top-markup-spacing = 0
  last-bottom-spacing = 0
}

%% Hide the copyright
#(define-markup-command (copyright layout props year composer) (number? string?)
  (interpret-markup layout props (markup)))
#(define-markup-command (copyrightNoYear layout props composer) (string?)
  (interpret-markup layout props (markup)))
