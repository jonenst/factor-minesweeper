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

TUPLE: minecell-gadget < checkbox minecell toplevel ;
TUPLE: minesweeper-gadget < pack timer now ;

: updater ( model -- timer )
  [ now swap set-model ] curry 1 seconds every ;
: ?start-now-model ( toplevel -- )
  dup timer>> [ drop ] [ dup now>> updater >>timer drop ] if ;
: stop-now-model ( toplevel -- )
  [ timer>> [ stop-timer ] when* ] [ f >>timer drop ] bi ;
: ?stop-now-model ( toplevel grid -- )
  finished?>> value>> [ stop-now-model ] [ drop ] if ;
: start/stop-now-model ( gadget -- )
  [ toplevel>> ] [ minecell>> grid>> ] bi
  [ drop ?start-now-model ] [ ?stop-now-model ] 2bi ;
: click ( gadget quot -- ) [ start/stop-now-model ] bi ; inline
: minecell-leftclicked ( gadget -- ) [ minecell>> demine-cell ] click ;
: minecell-rightclicked ( gadget -- ) [ minecell>> toggle-mark ] click ;

: minesweeper-image-pen ( string -- path )
  "vocab:minesweeper/" prepend-path ".png" append <image-name> <image-pen> ;
: minecell-theme ( gadget -- gadget )
  "cell-plain" minesweeper-image-pen dup
  "cell-pressed" minesweeper-image-pen dup dup <button-pen> >>interior
  dup dup interior>> pen-pref-dim >>min-dim { 10 0 } >>size ;

: <minecell-gadget> ( toplevel minecell -- gadget )
  [ ] [ cleared?>> ] [ <minecell-label> ] tri
  [ minecell-leftclicked ] minecell-gadget new-button
  swap >>model swap >>minecell swap >>toplevel
  minecell-theme ;

\ minecell-gadget {
  { T{ button-down f f 3 } [ drop ] }
  { T{ button-up f f 3 } [ minecell-rightclicked ] }
} set-gestures

: add-row ( pile toplevel cells -- pile )
  swap <shelf> [ <minecell-gadget> add-gadget ] with reduce
  add-gadget ;
: add-rows ( toplevel cells -- gadget )
  swap <pile> [ add-row ] with reduce ;

: <minegrid-gadget> ( toplevel grid -- gadget )
  cells>> add-rows ;

: status-str ( won? started? finished? -- str ) [ drop "Victory !" "BOOOOOM" ? ] [ nip "Playing" "Ready..." ? ] if ;
: <status-control> ( grid -- control )
  dup [ start>> ] [ finished?>> ] bi 2array <product>
  [ [ won?>> ] [ first2 status-str ] bi* ] with <arrow> <label-control> ;

: sanitize ( now start -- now' start' ) [ now or ] [ over or ] bi*  ;
: elapsed-time-str ( now start -- str )
  sanitize time- [ (timestamp>hms) ] with-string-writer ;
: elapsed-time-label ( start-model now-model -- label )
  [ elapsed-time-str ] <smart-arrow> <label-control> ;
: <elapsed-time-control> ( toplevel grid -- control )
  [ now>> ] [ start>> ] bi* elapsed-time-label ;
: <info-control> ( toplevel grid -- control )
  [ nip <status-control> ] [ <elapsed-time-control> ] 2bi
  <pile> swap add-gadget swap add-gadget ;
: info-container ( toplevel -- child ) gadget-child 1 swap nth-gadget ;
: info-gadget ( toplevel -- child ) info-container 1 swap nth-gadget ;
: add-info-control ( toplevel grid -- toplevel ) [ drop dup info-container ] [ <info-control> ] 2bi add-gadget drop ;

: minegrid-container ( toplevel -- child ) ;
: minegrid-gadget ( toplevel -- child ) minegrid-container 1 swap nth-gadget ;
: add-minegrid ( toplevel grid -- toplevel ) [ drop dup minegrid-container ] [ <minegrid-gadget> ] 2bi add-gadget drop ;

: add-game ( toplevel params -- )
  unclip-last <random-grid> [ add-info-control ] [ add-minegrid ] bi
  relayout-window ;
: remove-game ( toplevel -- )
  [ minegrid-gadget unparent ]
  [ info-gadget unparent ]
  [ stop-now-model ] tri  ;

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
    add-gadget
  add-gadget
  [ models models>values add-game ] keep ;

M: minesweeper-gadget ungraft* remove-game ;

: <minesweeper-main> ( -- gadget )
  \ minesweeper-gadget new vertical >>orientation f <model> >>now add-minesweeper-menu ;
: minesweeper-main ( -- )
  [ <minesweeper-main> "Minesweeper" open-window ] with-ui ;

MAIN: minesweeper-main
