! Copyright (C) 2012 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors colors combinators io.pathnames kernel locals
math math.parser models models.arrow.smart sequences ui
ui.gadgets ui.gadgets.buttons ui.gadgets.buttons.private
ui.gadgets.labels ui.gadgets.packs ui.gestures ui.images
ui.pens ui.pens.image ui.pens.solid ui.render ;
IN: minesweeper

TUPLE: minecell mined? selected guess ;
: <minecell> ( mined? -- minecell ) f <model> f <model> \ minecell boa ;

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

: minesweeper-main ( -- )
  t <minecell> <minecell-gadget>
  f <minecell> <minecell-gadget> 
  <shelf> swap add-gadget swap add-gadget
  "minesweeper" open-window ;

MAIN: minesweeper-main
