! Copyright (C) 2012 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors combinators grouping io.pathnames kernel
locals math math.parser minesweeper.engine models
models.arrow.smart sequences ui ui.gadgets ui.gadgets.buttons
ui.gadgets.buttons.private ui.gadgets.labels ui.gadgets.packs
ui.gestures ui.images ui.pens ui.pens.image ;
IN: minesweeper

: neighbours-string ( n -- string )
   [ "" ] [ number>string ] if-zero ;
:: minecell-label ( selected guess mined? neighbours -- str )
  selected [ mined? "X" neighbours neighbours-string ? ]
  [ guess "!" "" ? ] if ;
: <minecell-label> ( minecell -- label )
  { [ selected>> ] [ guess>> ]
    [ mined?>> <model> ] [ drop 1 <model> ]
  } cleave
  [ minecell-label ] <smart-arrow> <label-control> ;

TUPLE: minecell-gadget < checkbox minecell ;
: minecell-leftclicked ( gadget -- )
  minecell>> selected>> t swap set-model ;
: minecell-rightclicked ( gadget -- )
  minecell>> guess>> toggle-model ;

: minesweeper-image-pen ( string -- path )
  "vocab:minesweeper/" prepend-path ".png" append <image-name> <image-pen> ;
: minecell-theme ( gadget -- gadget )
  "cell-plain" minesweeper-image-pen dup
  "cell-pressed" minesweeper-image-pen dup dup <button-pen> >>interior
  dup dup interior>> pen-pref-dim >>min-dim { 10 0 } >>size  ; 

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
  <pile> [ add-row  ] reduce ;

: <minesweeper-gadget> ( grid -- gadget )
  [ m>> ] [ cells>> ] bi swap group add-rows ;

: minesweeper-main ( -- )
  { 3 3 } <empty-grid> <minesweeper-gadget>
  "minesweeper" open-window ;

MAIN: minesweeper-main
