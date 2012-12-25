! Copyright (C) 2012 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays combinators combinators.short-circuit
generalizations io.pathnames kernel locals math math.parser
minesweeper.engine minesweeper.engine.neighbours
minesweeper.gui.cell.font minesweeper.gui.cell.label
minesweeper.gui.layout minesweeper.gui.theme models
models.arrow.smart models.product namespaces sequences
ui.gadgets ui.gadgets.buttons ui.gadgets.buttons.private
ui.gadgets.labels ui.gestures ui.images ui.pens ui.pens.image ;
IN: minesweeper.gui.cell

TUPLE: minecell-gadget < checkbox minecell toplevel ;

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


