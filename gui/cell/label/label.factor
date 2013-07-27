! Copyright (C) 2012 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays combinators generalizations kernel
locals math math.parser minesweeper.engine.private
minesweeper.gui.font minesweeper.gui.theme models
models.arrow.smart models.product sequences ui.gadgets
ui.gadgets.labels ;
IN: minesweeper.gui.cell.label

TUPLE: fancy-label-control < label ;
: <fancy-label-control> ( model -- label )
  "" fancy-label-control new-label swap >>model ;
M: fancy-label-control model-changed
  swap value>> [ first >>string ] [ second >>font ] bi relayout ;

: neighbours-string ( n -- string )
   [ "" ] [ number>string ] if-zero ;
:: minecell-label ( cleared? marked? mined? neighbours -- str )
  cleared? [ mined? BOOM neighbours neighbours-string ? ]
  [ marked? MARK "" ? ] if ;
: <neighbour-mines-model> ( minecell -- model )
  neighbour-cells [ mined?>> ] map <product> [ [ ] count ] <arrow> ;
: <minecell-label> ( minecell -- label )
  { [ cleared?>> ] [ marked?>> ]
    [ mined?>> ] [ <neighbour-mines-model> ]
  } cleave
  { [ [ minecell-label ] <smart-arrow> ]
  [ [ minesweeper-font ] <smart-arrow> ] } 4 ncleave
  2array <product> <fancy-label-control> ;

