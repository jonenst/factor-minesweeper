! Copyright (C) 2012 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays colors colors.constants combinators
combinators.short-circuit fonts formatting generalizations
io.pathnames io.streams.string kernel locals math math.order
math.parser minesweeper.engine models models.arrow
models.arrow.smart models.product namespaces sequences
sequences.extras ui ui.commands ui.gadgets ui.gadgets.buttons
ui.gadgets.buttons.private ui.gadgets.editors
ui.gadgets.labeled ui.gadgets.labels ui.gadgets.packs
ui.gestures ui.images ui.pens ui.pens.image ;
FROM: models => change-model ;
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
TUPLE: minesweeper-gadget < pack current-grid ;

: info-container ( toplevel -- child ) gadget-child 1 swap nth-gadget ;
: info-gadget ( toplevel -- child ) info-container 1 swap nth-gadget ;
: minegrid-container ( toplevel -- child ) ;
: minegrid-gadget ( toplevel -- child ) minegrid-container 1 swap nth-gadget ;

: neighbour-expanded-indices ( gadget -- indices )
  minecell>> neighbour-cells
  [ marked?>> value>> not ] filter
  [ idx>> ] map ;
: Mi,j-gadget ( {i,j} gadget -- child )
  [ swap nth-gadget ] reduce ;
: neighbour-expanded-buttons ( gadget -- buttons )
  [ neighbour-expanded-indices ] [ toplevel>> minegrid-gadget ] bi
  [ Mi,j-gadget ] curry map ;
: neighbour-expanded-button-update ( gadget neighbour -- )
  swap
  { [ mouse-clicked? ] [ button-rollover? ] } 1&&
  buttons-down? and
  >>pressed?
  relayout-1 ;
: update-neighbours ( gadget -- )
  dup neighbour-expanded-buttons [ neighbour-expanded-button-update ] with each ;

: (minecell-midclicked) ( gadget -- ) minecell>> ?expand-cell ;
: (minecell-leftclicked) ( gadget -- ) minecell>> demine-cell ;
: (minecell-rightclicked) ( gadget -- ) minecell>> toggle-mark ;

: minecell-midclicked ( gadget -- )
  [ [ button-update ] [ update-neighbours ] bi ]
  [ dup button-rollover? [ (minecell-midclicked) ] [ drop ] if ] bi ;
: minecell-rightclicked ( gadget -- )
  dup button-rollover? [ (minecell-rightclicked) ] [ drop ] if ;

: minesweeper-image-pen ( string -- path )
  "vocab:minesweeper/" prepend-path ".png" append <image-name> <image-pen> ;
: minecell-theme ( gadget -- gadget )
  "cell-plain" minesweeper-image-pen dup
  "cell-pressed" minesweeper-image-pen dup dup <button-pen> >>interior
  dup dup interior>> pen-pref-dim >>min-dim { 10 0 } >>size ;

: <minecell-gadget> ( toplevel minecell -- gadget )
  [ ] [ cleared?>> ] [ <minecell-label> ] tri
  [ (minecell-leftclicked) ] minecell-gadget new-button
  swap >>model swap >>minecell swap >>toplevel
  minecell-theme ;

: midclicking? ( -- ? ) 2 hand-buttons get-global member? ;
: update-midclick ( gadget -- )
  midclicking? [
    dup mouse-clicked? [
      [ button-update ] [ update-neighbours ] bi
    ] [ drop ] if
  ] [ button-update ] if ;

\ minecell-gadget {
  { T{ button-up f f 2 } [ minecell-midclicked ] }
  { T{ button-up f f 3 } [ minecell-rightclicked ] }
  { T{ button-down f f 3 } [ drop ] }
  { T{ button-down f f 2 } [ update-neighbours ] }
  { mouse-leave [ update-midclick ] }
  { mouse-enter [ update-midclick ] }
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
  dup [ started?>> ] [ finished?>> ] bi 2array <product>
  [ [ won?>> ] [ first2 status-str ] bi* ] with <arrow> <label-control> ;

: elapsed-time-str ( seconds -- str )
  60 /mod [ 60 /mod ] dip [ "%02d:%02d:%02d" printf ] with-string-writer ;
: elapsed-time-label ( duration-model -- label )
  [ elapsed-time-str ] <arrow> <label-control> ;
: <elapsed-time-control> ( grid -- control )
  duration>> elapsed-time-label ;
: <info-control> ( grid -- control )
  [ <status-control> ] [ <elapsed-time-control> ] bi
  <pile> swap add-gadget swap add-gadget ;
: add-info-control ( toplevel grid -- toplevel ) [ dup info-container ] [ <info-control> ] bi* add-gadget drop ;

: add-minegrid ( toplevel grid -- toplevel ) [ drop dup minegrid-container ] [ <minegrid-gadget> ] 2bi add-gadget drop ;

: add-game ( toplevel params -- )
  unclip-last <timed-random-grid> [ >>current-grid ] [ add-info-control ] [ add-minegrid ] tri
  relayout-window ;
: remove-game ( toplevel -- )
  [ minegrid-gadget unparent ]
  [ info-gadget unparent ]
  [ current-grid>> stop-callbacks ] tri  ;

: new-game ( toplevel params -- )
  [ drop remove-game ] [ add-game ] 2bi ;

: find-children ( gadget quot: ( child -- ? ) -- children )
  [ dupd call [ drop f ] unless ]
  [ [ children>> ] dip [ find-children ] curry map concat ] 2bi
  swap prefix sift ; inline recursive

TUPLE: tabbed-model-field < model-field prev next ;
: <tabbed-model-field> ( model -- gadget )
  tabbed-model-field new-field swap >>field-model ;

: com-next ( gadget -- ) next>> editor>> request-focus ;
: com-prev ( gadget -- ) prev>> editor>> request-focus ;
\ tabbed-model-field "editing" f {
  { T{ key-down f f "TAB" } com-next }
  { T{ key-down f { S+ } "TAB" } com-prev }
} define-command-map

: link-tabbed-gadget ( prev cur next -- ) >>next prev<< ;
: link-tabbed-gadgets ( tabbed-gadgets -- )
  [ dup length 1 - 0 max rotate ] [ ] [ dup length 1 - 0 1 clamp rotate ] tri
  [ link-tabbed-gadget ] 3each ;
: link-all-tabbed-gadgets ( gadget -- )
  [ tabbed-model-field? ] find-children link-tabbed-gadgets ;

: add-fields ( parent default-params -- parent models )
  { "rows" "cols" "mines" } swap [ <model> ] map [
    [ <tabbed-model-field> swap <labeled-gadget> ] 2map add-gadgets
    dup link-all-tabbed-gadgets
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
  \ minesweeper-gadget new vertical >>orientation add-minesweeper-menu ;
: minesweeper-main ( -- )
  [ <minesweeper-main> "Minesweeper" open-window ] with-ui ;

MAIN: minesweeper-main
