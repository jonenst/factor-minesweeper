! Copyright (C) 2012 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors colors colors.constants combinators fonts
grouping gtk.ffi io.pathnames kernel locals math math.order
math.parser minesweeper.engine models models.arrow.smart
sequences ui ui.gadgets ui.gadgets.buttons
ui.gadgets.buttons.private ui.gadgets.editors
ui.gadgets.labeled ui.gadgets.labels ui.gadgets.packs
ui.gadgets.worlds ui.gestures ui.images ui.pens ui.pens.image ;
IN: minesweeper

CONSTANT: number-colors {
  COLOR: blue
  COLOR: DarkGreen
  COLOR: red
}

: minesweeper-label-theme ( n label -- label )
  [
    [ 1 - 0 2 clamp number-colors nth ] [ swap font-with-foreground ] bi*
    T{ rgba f 1 0 0 0 } font-with-background
    t >>bold?
  ] with change-font ;
: neighbours-string ( n -- string )
   [ "" ] [ number>string ] if-zero ;
:: minecell-label ( selected guess mined? neighbours -- str )
  selected [ mined? "X" neighbours neighbours-string ? ]
  [ guess "!" "" ? ] if ;
: <minecell-label> ( minecell -- label )
  { [ selected>> ] [ guess>> ]
    [ mined?>> <model> ] [ neighbour-mines <model> ]
  } cleave
  [ [ minecell-label ] <smart-arrow> <label-control> ]
  [ value>> swap minesweeper-label-theme ] bi ;

TUPLE: minecell-gadget < checkbox minecell ;
: check-end ( grid -- )
  finished? [ "lose" "win" ? "You" "!" surround <label> "minesweeper" open-window ] [ drop ] if ;
: minecell-leftclicked ( gadget -- )
  minecell>> [ demine-cell ] [ grid>> check-end ] bi ;
: minecell-rightclicked ( gadget -- )
  minecell>> guess>> toggle-model ;

: minesweeper-image-pen ( string -- path )
  "vocab:minesweeper/" prepend-path ".png" append <image-name> <image-pen> ;
: minecell-theme ( gadget -- gadget )
  "cell-plain" minesweeper-image-pen dup
  "cell-pressed" minesweeper-image-pen dup dup <button-pen> >>interior
  dup dup interior>> pen-pref-dim >>min-dim { 10 0 } >>size ;

: <minecell-gadget> ( minecell -- gadget )
  [ ] [ selected>> ] [ <minecell-label> ] tri
  [ minecell-leftclicked ] minecell-gadget new-button
  swap >>model swap >>minecell
  minecell-theme ;

\ minecell-gadget {
  { T{ button-down f f 3 } [ drop ] }
  { T{ button-up f f 3 } [ minecell-rightclicked ] }
} set-gestures

: add-row ( pile cells -- pile )
  <shelf> [ <minecell-gadget> add-gadget ] reduce add-gadget ;
: add-rows ( cells -- gadget )
  <pile> [ add-row ] reduce ;

: <minesweeper-gadget> ( grid -- gadget )
  cells>> add-rows ;

: adapt-window ( gadget -- )
  dup find-world [
    swap [ handle>> window>> ] [ pref-dim first2 ] bi* gtk_window_resize
  ] [ drop ] if* ;
: add-game ( toplevel params -- )
  unclip-last <random-grid> <minesweeper-gadget> add-gadget adapt-window ;
: remove-game ( toplevel -- )
  1 swap nth-gadget unparent ;
: new-game ( toplevel params -- )
  [ drop remove-game ] [ add-game ] 2bi ;

: add-fields ( parent default-params -- parent models )
  { "rows:" "cols:" "mines:" } swap [ <model> ] map [
    [ <model-field> swap <labeled-gadget> ] 2map add-gadgets
  ] keep ;

:: add-minesweeper-menu ( default-params toplevel -- menu )
  toplevel <shelf> default-params add-fields :> models
  "New game" [
    drop toplevel
    models [ value>> string>number ] map new-game
  ] <border-button> add-gadget
  add-gadget ;
: <minesweeper-main> ( default-params -- gadget )
  <pile> add-minesweeper-menu ;
: minesweeper-main ( -- )
  { "5" "5" "5" }
  [ <minesweeper-main> dup ]
  [ [ string>number ] map add-game ] bi
  "minesweeper" open-window ;

MAIN: minesweeper-main
