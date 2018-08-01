! Copyright (C) 2012 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays formatting io.streams.string kernel
locals math math.parser minesweeper minesweeper.gui.cell
minesweeper.engine minesweeper.gui.layout
minesweeper.gui.tabbed-field models models.arrow models.product
sequences ui ui.gadgets ui.gadgets.buttons ui.gadgets.labeled
ui.gadgets.labels ui.gadgets.packs minesweeper.engine.timed-grid 
minesweeper.engine.finish minesweeper.atomic-products ;
FROM: sequences => product ;
IN: minesweeper.gui

TUPLE: minesweeper-gadget < pack current-grid ;

: add-row ( pile toplevel cells -- pile )
  swap <shelf> [ <minecell-gadget> add-gadget ] with reduce
  add-gadget ;
: add-rows ( toplevel cells -- gadget )
  swap <pile> [ add-row ] with reduce ;

: <minegrid-gadget> ( toplevel grid -- gadget )
  cells>> add-rows ;

: status-str ( won? started? finished? -- str ) [ drop "Victory !" "BOOOOOM" ? ] [ nip "Playing" "Ready..." ? ] if ;
: <status-control> ( grid -- control )
  dup [ started?>> ] [ finished?>> ] bi 2array <atomic-product>
  [ [ won?>> ] [ first2 status-str ] bi* ] with <arrow> <label-control> ;

: elapsed-time-str ( seconds -- str )
  60 /mod [ 60 /mod ] dip [ "%02d:%02d:%02d" printf ] with-string-writer ;
: elapsed-time-label ( duration-model -- label )
  [ elapsed-time-str ] <arrow> <label-control> ;
: <elapsed-time-control> ( grid -- control )
  duration>> elapsed-time-label ;
: (<mark-control>) ( model cells total-mines -- label-control )
  [ [ marked-count ] [ "marks: %d/%d" sprintf ] bi* nip ] 2curry
  <arrow> <label-control> ;
: <mark-control> ( grid -- control )
  [ cells>> concat ] [ total-mines>> ] bi
  [ drop [ marked?>> ] map <atomic-product> ]
  [ (<mark-control>) ] 2bi ;
: <info-control> ( grid -- control )
  [ <status-control> ] [ <elapsed-time-control> ] [ <mark-control> ] tri
  <pile> swap add-gadget swap add-gadget swap add-gadget ;
: add-info-control ( toplevel grid -- toplevel ) [ dup info-container ] [ <info-control> ] bi* add-gadget drop ;

: add-minegrid ( toplevel grid -- toplevel ) [ drop dup minegrid-container ] [ <minegrid-gadget> ] 2bi add-gadget drop ;

: add-game ( toplevel params -- )
  unclip-last <timed-random-grid> [ >>current-grid ] [ add-info-control ] [ add-minegrid ] tri
  relayout-window ;
: remove-game ( toplevel -- )
  [ minegrid-gadget unparent ]
  [ info-gadget unparent ]
  [ current-grid>> stop-callbacks ] tri  ;
M: minesweeper-gadget ungraft* remove-game ;

: validate-params ( models -- ? ) unclip-last [ product 1 - ] [ >= ] bi* ;
: new-game ( toplevel params -- )
  dup validate-params [
    [ drop remove-game ] [ add-game ] 2bi
  ] [ 2drop ] if ;

: add-fields ( parent default-params -- parent models )
  { "rows" "cols" "mines" } swap [ <model> ] map [
    [ <tabbed-model-field> swap <labeled-gadget> ] 2map add-gadgets
    dup link-all-tabbed-gadgets
  ] keep ;

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

: <minesweeper-gui> ( -- gadget )
  \ minesweeper-gadget new
   vertical >>orientation
   add-minesweeper-menu ;
: minesweeper-gui ( -- )
  [ <minesweeper-gui> "Minesweeper" open-window ] with-ui ;

MAIN: minesweeper-gui
