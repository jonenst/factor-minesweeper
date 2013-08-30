! Copyright (C) 2012 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays calendar combinators
combinators.short-circuit
compiler.cfg.linear-scan.allocation.state fry kernel math
math.order math.ranges math.vectors
minesweeper.engine.neighbours
minesweeper.engine.neighbours.private minesweeper.matrix-utils
models models.arrow models.product random sequences
sequences.extras sequences.product timers formatting minesweeper.atomic-products ;
FROM: models => change-model ;
FROM: sequences => product ;
IN: minesweeper.engine

: marked-count ( cells -- n ) [ [ marked?>> value>> ] [ cleared?>> value>> not ] bi and ] count ;
<PRIVATE
: mines-count ( cells -- n ) [ mined?>> value>> ] count ;
: neighbour-mines ( minecell -- n ) neighbour-cells mines-count ;

DEFER: (demine-cell)
: ?demine-neighbours ( minecell -- )
  dup [ neighbour-mines zero? ] [ mined?>> value>> not ] bi and [
    [ [ idx>> ] [ grid>> dim>> ] bi neighbours ]
    [ grid>> cells>> ] bi [
      Mi,j (demine-cell)
    ] curry each
  ] [ drop ] if ;
: (demine-cell) ( minecell -- )
  dup cleared?>> value>> [ drop ] [
    [ cleared?>> t swap set-model ]
    [ ?demine-neighbours ] bi
  ] if ;
PRIVATE>

: obvious? ( cells -- ? ) [ cleared?>> value>> ] all? ;
: mark ( cell -- ) marked?>> t swap set-model ;
: ?mark-obvious ( cell -- )
  dup neighbour-cells obvious? [ mark ] [ drop ] if ;
: cleared-count ( grid -- n )
  cells>> concat [ cleared?>> value>> ] count ;
: cleared-total ( grid -- n )
  [ dim>> product ] [ total-mines>> ] bi - ;
: mark-all ( grid -- )
  cells>> [ mark ] meach ;
: ?mark-remaining ( cell -- )
  grid>> dup [ cleared-count ] [ cleared-total ] bi =
  [ mark-all ] [ drop ] if ;
: mark-obvious-cells ( minecell -- )
  grid>> cells>> [ ?mark-obvious ] meach ;


<PRIVATE
: demine-mark ( minecell -- )
  [ (demine-cell) ]
  [ mark-obvious-cells ]
  [ ?mark-remaining ] tri ;

: add-mines ( indices cells -- ) [ Mi,j mined?>> t swap set-model ] curry each ;
: init-mines ( minecell -- )
  [ idx>> ] [ grid>> {
    [ dim>> ]
    [ total-mines>> ]
    [ init-mines-quot>> ]
    [ cells>> ]
   } cleave ] bi [ call( {i,j} dim mines -- indices ) ] [ add-mines ] bi* ;
: ?init-mines ( minecell -- )
  dup grid>> started?>> value>> [ drop ] [ init-mines ] if ;
PRIVATE>
: demine-cell ( minecell -- ) [ [ ?init-mines ] [ demine-mark ] bi ] with-atomic-products ;

<PRIVATE
: toggle-model ( model -- ) [ not ] change-model ;
PRIVATE>
: toggle-mark ( minecell -- ) marked?>> toggle-model ;
: ?expand-cell ( minecell -- )
  dup cleared?>> value>> [
    neighbour-cells dup [ mines-count ] [ marked-count ] bi = [
      [ marked?>> value>> not ] filter [ demine-cell ] each
    ] [ drop ] if
  ] [ drop ] if ;
