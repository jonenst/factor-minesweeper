! Copyright (C) 2012 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors calendar calendar.format colors
colors.constants combinators fonts grouping gtk.ffi
io.pathnames io.streams.string kernel locals math math.order
math.parser minesweeper.engine models models.arrow
models.arrow.smart sequences timers ui ui.gadgets
ui.gadgets.buttons ui.gadgets.buttons.private
ui.gadgets.editors ui.gadgets.labeled ui.gadgets.labels
ui.gadgets.packs ui.gadgets.worlds ui.gestures ui.images
ui.pens ui.pens.image ;
IN: minesweeper

CONSTANT: number-colors {
  COLOR: blue
  COLOR: DarkGreen
  COLOR: red
}

: base-theme ( label -- label )
  t >>bold?  T{ rgba f 1 0 0 0 } font-with-background ;
: unmined-theme ( n label -- label )
  base-theme 
  [ 1 - 0 2 clamp number-colors nth ]
  [ swap font-with-foreground ] bi* ;
: guess-theme ( label -- label )
  base-theme COLOR: black font-with-foreground ;
: minesweeper-label-theme ( label guess mined? n -- label )
  -rot [ {
    { [ ] [ 2drop guess-theme ] }
    { [ ] [ drop guess-theme ] }
    [ swap unmined-theme ]
  } cond ] 3curry change-font ;
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
  [ [ value>> ] tri@ minesweeper-label-theme ] 3bi ;

TUPLE: minecell-gadget < checkbox minecell ;
: check-end ( grid -- )
  finished? [ "lose" "win" ? "You" "!" surround <label> "minesweeper" open-window ] [ drop ] if ;
: apply-label-theme ( gadget -- )
[ gadget-child ] [ minecell>>
  [ guess>> value>> ]
  [ mined?>> ]
  [ neighbour-mines ] tri
] bi minesweeper-label-theme drop ;

: minecell-leftclicked ( gadget -- )
  [ minecell>> [ demine-cell ] [ grid>> check-end ] bi ]
  [ apply-label-theme ] bi ;
: minecell-rightclicked ( gadget -- )
  [ minecell>> guess>> toggle-model ]
  [ apply-label-theme ] bi ;

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

: add-game ( toplevel finish-model params -- )
  unclip-last <random-grid> <minesweeper-gadget> add-gadget relayout-window ;
: remove-game ( toplevel finish-model -- )
  [ 1 swap nth-gadget unparent ] [ f swap set-model ] bi* ;
: new-game ( toplevel finish-model params -- )
  [ drop remove-game ] [ add-game ] 3bi ;

: add-fields ( parent default-params -- parent models )
  { "rows:" "cols:" "mines:" } swap [ <model> ] map [
    [ <model-field> swap <labeled-gadget> ] 2map add-gadgets
  ] keep ;

:: add-minesweeper-menu ( default-params toplevel -- toplevel finish-model )
  toplevel <shelf> default-params add-fields :> models
  f <model> :> finish-model
  <pile>
    "New game" [
      drop toplevel finish-model
      models [ value>> string>number ] map new-game
    ] <border-button> add-gadget
    finish-model [let now :> previous! [ [ previous ] [ now dup previous! ] if ] ] <arrow> :> last-started
    now <model> :> now-model
    [ finish-model value>> [ now now-model set-model ] unless ] 1 seconds every drop
    now-model last-started [ time- 1 seconds time+ [ (timestamp>hms) ] with-string-writer ]
    <smart-arrow> <label-control> add-gadget
  add-gadget
  add-gadget finish-model ;
: <minesweeper-main> ( default-params -- gadget finish-model )
  <pile> add-minesweeper-menu ;
: minesweeper-main ( -- )
  { "5" "5" "5" }
  [ <minesweeper-main> dupd ]
  [ [ string>number ] map add-game ] bi
  "minesweeper" open-window ;

MAIN: minesweeper-main
