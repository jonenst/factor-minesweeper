! Copyright (C) 2012 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays combinators generalizations kernel
locals math math.parser minesweeper.engine.neighbours
minesweeper.engine.private minesweeper.gui.font
minesweeper.gui.theme models models.arrow models.arrow.smart
models.product sequences ui.gadgets ui.gadgets.labels minesweeper.atomic-products ;
IN: minesweeper.gui.cell.label

TUPLE: fancy-label-control < label ;
: <fancy-label-control> ( model -- label )
  "" fancy-label-control new-label swap >>model ;
M: fancy-label-control model-changed
  swap value>> [ first >>string ] [ second >>font ] bi relayout ;

: neighbours-string ( n -- string )
   [ "" ] [ number>string ] if-zero ;
:: minecell-label ( cleared? marked? mined? neighbours finished? -- str )
  cleared? [ mined? BOOM neighbours neighbours-string ? ]
  [ marked? MARK finished? mined? and "@" "" ? ? ] if ;
: <neighbour-mines-model> ( minecell -- model )
  neighbour-cells [ mined?>> ] map <atomic-product> [ [ ] count ] <arrow> ;
: <minecell-label> ( minecell -- label )
  { [ cleared?>> ] [ marked?>> ]
    [ mined?>> ] [ <neighbour-mines-model> ]
    [ grid>> finished?>> ]
  } cleave
  { [ [ minecell-label ] <smart-arrow> ]
  [ [ minesweeper-font ] <smart-arrow> ] } 5 ncleave
  2array <atomic-product> <fancy-label-control> ;

