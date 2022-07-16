\layout {
  \context {
    \Score
    barNumberFormatter = #bar-numbers-formatter
    \remove "Bar_number_engraver"
  }

  \context {
    \Staff
    \consists "Bar_number_in_instrument_name_engraver"
    \override InstrumentName.font-size = #-2
    \override InstrumentName.padding = #1
  }
}
