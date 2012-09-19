! Copyright (C) 2012 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays calendar calendar.format colors
colors.constants combinators fonts generalizations grouping
gtk.ffi io.pathnames io.streams.string kernel locals math
math.order math.parser minesweeper.engine models models.arrow
models.arrow.smart models.product sequences timers ui
ui.gadgets ui.gadgets.buttons ui.gadgets.buttons.private
ui.gadgets.editors ui.gadgets.labeled ui.gadgets.labels
ui.gadgets.packs ui.gadgets.worlds ui.gestures ui.images
ui.pens ui.pens.image ;
IN: minesweeper

CONSTANT: number-colors {
  COLOR: blue
  COLOR: DarkGreen
  COLOR: red
}

TUPLE: fancy-label-control < label ;
: <fancy-label-control> ( model -- label )
  "" fancy-label-control new-label swap >>model ;
M: fancy-label-control model-changed
  swap value>> [ first >>string ] [ second >>font ] bi relayout ;

: base-font ( font -- font )
  t >>bold?  T{ rgba f 1 0 0 0 } font-with-background ;
: cleared-font ( n font -- font )
  base-font
  [ 1 - 0 2 clamp number-colors nth ]
  [ swap font-with-foreground ] bi* ;
: marked-font ( font -- font )
  base-font COLOR: black font-with-foreground ;
: explosion-font ( font -- font )
  base-font COLOR: DarkRed font-with-foreground ;

:: minesweeper-font ( cleared? marked? mined? n -- font )
  sans-serif-font {
    { [ cleared? mined? and ] [ explosion-font ] }
    { [ cleared? mined? not and ] [ n swap cleared-font ] }
    { [ marked? ] [ marked-font ] }
    [ base-font ]
  } cond ;

: neighbours-string ( n -- string )
   [ "" ] [ number>string ] if-zero ;
:: minecell-label ( cleared? marked? mined? neighbours -- str )
  cleared? [ mined? "X" neighbours neighbours-string ? ]
  [ marked? "!" "" ? ] if ;
: <minecell-label> ( minecell -- label )
  { [ cleared?>> ] [ marked?>> ]
    [ mined?>> <model> ] [ neighbour-mines <model> ]
  } cleave
  { [ [ minecell-label ] <smart-arrow> ]
  [ [ minesweeper-font ] <smart-arrow> ] } 4 ncleave
  2array <product> <fancy-label-control> ;

TUPLE: minecell-gadget < checkbox minecell ;

: minecell-leftclicked ( gadget -- ) minecell>> demine-cell ;
: minecell-rightclicked ( gadget -- ) minecell>> marked?>> toggle-model ;

: minesweeper-image-pen ( string -- path )
  "vocab:minesweeper/" prepend-path ".png" append <image-name> <image-pen> ;
: minecell-theme ( gadget -- gadget )
  "cell-plain" minesweeper-image-pen dup
  "cell-pressed" minesweeper-image-pen dup dup <button-pen> >>interior
  dup dup interior>> pen-pref-dim >>min-dim { 10 0 } >>size ;

: <minecell-gadget> ( minecell -- gadget )
  [ ] [ cleared?>> ] [ <minecell-label> ] tri
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

: <minegrid-gadget> ( grid -- gadget )
  cells>> add-rows ;

: status-str ( won? finished? -- str ) [ "Victory !" "BOOOOOM" ? ] [ drop "Playing" ] if ;
: <status-control> ( grid -- control )
  dup finished?>> [ [ won?>> ] [ status-str ] bi* ] with <arrow> <label-control> ;
: status-container ( toplevel -- child ) gadget-child 1 swap nth-gadget ;
: status-gadget ( toplevel -- child ) status-container 1 swap nth-gadget ;
: add-status-control ( toplevel grid -- toplevel ) [ dup status-container ] [ <status-control> ] bi* add-gadget drop ;

: minegrid-container ( toplevel -- child ) ;
: minegrid-gadget ( toplevel -- child ) minegrid-container 1 swap nth-gadget ;
: add-minegrid ( toplevel grid -- toplevel ) [ dup minegrid-container ] [ <minegrid-gadget> ] bi* add-gadget drop ;

: add-game ( toplevel params -- )
  unclip-last <random-grid> [ add-status-control ] [ add-minegrid ] bi
  relayout-window ;
: remove-game ( toplevel -- )
  [ minegrid-gadget unparent ] [ status-gadget unparent ] bi  ;

: new-game ( toplevel params -- )
  [ drop remove-game ] [ add-game ] 2bi ;

: add-fields ( parent default-params -- parent models )
  { "rows:" "cols:" "mines:" } swap [ <model> ] map [
    [ <model-field> swap <labeled-gadget> ] 2map add-gadgets
  ] keep ;

CONSTANT: default-params { "5" "5" "5" }
: models>values ( models -- values ) [ value>> string>number ] map ;
:: add-minesweeper-menu ( toplevel -- toplevel )
  toplevel
  <shelf>
    <shelf> default-params add-fields :> models add-gadget
    <pile>
      "New game" [
        drop toplevel
        models models>values new-game
      ] <border-button> add-gadget
!    finish-model [let now :> previous! [ [ previous ] [ now dup previous! ] if ] ] <arrow> :> last-started
!    now <model> :> now-model
!    [ finish-model value>> [ now now-model set-model ] unless ] 1 seconds every drop
!    now-model last-started [ time- 1 seconds time+ [ (timestamp>hms) ] with-string-writer ]
!    <smart-arrow> <label-control> add-gadget
    add-gadget
  add-gadget
  [ models models>values add-game ] keep ;

TUPLE: minesweeper-gadget < pack ;
: <minesweeper-main> ( -- gadget )
  \ minesweeper-gadget new vertical >>orientation add-minesweeper-menu ;
: minesweeper-main ( -- )
  [ <minesweeper-main> "Minesweeper" open-window ] with-ui ;

MAIN: minesweeper-main
