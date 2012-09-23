! Copyright (C) 2012 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays calendar combinators.short-circuit fry
kernel math math.order math.ranges math.vectors models
models.arrow models.product random sequences sequences.extras
sequences.product ;
FROM: models => change-model ;
FROM: sequences => product ;
IN: minesweeper.engine

TUPLE: minecell idx mined? grid cleared? marked? ;
TUPLE: grid dim cells total-mines start finished? won? ;

: cleared-all? ( cells -- ? )
  [ [ mined?>> not ] [ cleared?>> value>> not ] bi and ] none? ;
: marked-all? ( cells -- ? )
  [ [ mined?>> ] [ marked?>> value>> not ] bi and ] none? ;
: won? ( seq -- ? ) { [ cleared-all? ] [ marked-all? ] } 1&& ;
: lost? ( grid -- ? )
  [ [ mined?>> ] [ cleared?>> value>> ] bi and ] any? ;
: finished? ( grid -- won? finished? )
  cells>> concat [ won? ] [ lost? ] bi [ drop ] [ or ] 2bi ;

: save-grid-start ( minecell -- )
  grid>> start>> dup value>> [ drop ] [ now swap set-model ] if ;
: click ( mincell quot -- ) [ save-grid-start ] bi ; inline

: <matrix> ( dim n -- matrix )
  [ first2 ] [ '[ _ [ _ ] replicate ] replicate ] bi* ;
: Mi,j ( idx M -- x )
  [ swap nth ] reduce ;
: Mi,js ( seq M -- seq )
  [ Mi,j ] curry map ;
: Mi,j! ( el idx M -- )
  [ first2 swap ] [ nth set-nth ] bi* ;
: meach ( ... M quot: ( ... el -- ... ) -- ... )
  [ each ] curry each ; inline
: mmap-index ( ... M quot: ( ... el idx -- ... el ) -- ... M' )
  [ swap 2array ] prepose
  [ curry map-index ] curry map-index ; inline
: mmap-index* ( M quot: ( ... idx -- ... el ) -- ... M' )
  [ nip ] prepose mmap-index ; inline
: <matrix*> ( dim quot: ( ... idx -- ... el ) -- ... )
  [ f <matrix> ] [ mmap-index* ] bi* ; inline

: (all-neighbours) ( idx n -- seq )
 [ neg ] keep [a,b] dup 2array [ v+ ] with product-map ;
: all-neighbours ( idx n -- seq )
  [ (all-neighbours) ] [ drop swap remove ] 2bi ;
: in-range? ( idx dim -- ? )
  [ 1 - 0 swap between? ] 2all? ;
: neighbours ( idx dim -- seq )
  [ 1 all-neighbours ] [ [ in-range? ] curry filter ] bi* ;
: (neighbour-cells) ( idx grid -- cells )
  [ dim>> neighbours ] [ nip cells>> ] 2bi Mi,js ;
: neighbour-cells ( cell -- cells )
  [ idx>> ] [ grid>> ] bi (neighbour-cells) ;
: mines-count ( cells -- n ) [ mined?>> ] count ;
: marked-count ( cells -- n ) [ [ marked?>> value>> ] [ cleared?>> value>> not ] bi and ] count ;
: neighbour-mines ( minecell -- n ) neighbour-cells mines-count ;
: neighbour-marked ( minecell -- n ) neighbour-cells marked-count  ;

DEFER: (demine-cell)
: ?demine-neighbours ( minecell -- )
  dup [ neighbour-mines zero? ] [ mined?>> not ] bi and [
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

: <minecell> ( idx mined? grid -- minecell )
  f <model> f <model> \ minecell boa ;


: check-finished ( grid -- finished? )
  dup finished? [ >>won? drop ] dip ;

: <finish-in-model> ( cells -- model )
  concat [ cleared?>> ] [ marked?>> ] [ map <product> ] bi-curry@ bi 2array <product> ;
: <finish-arrow> ( grid -- arrow )
  [ cells>> <finish-in-model> ]
  [ [ nip check-finished ] curry ] bi <arrow> ;

: demine-mark ( minecell -- )
  [ (demine-cell) ]
  [ mark-obvious-cells ]
  [ ?mark-remaining ] tri ;
: demine-cell ( minecell -- ) [ demine-mark ] click ;
: toggle-model ( model -- ) [ not ] change-model ;
: toggle-mark ( minecell -- ) [ marked?>> toggle-model ] click ;
: ?expand-cell ( minecell -- )
  dup cleared?>> value>> [
    neighbour-cells dup [ mines-count ] [ marked-count ] bi = [
      [ marked?>> value>> not ] filter [ demine-cell ] each
    ] [ drop ] if
  ] [ drop ] if ;

: <grid> ( dim mines quot: ( dim mines grid -- cells ) -- grid )
  [ \ grid new ] dip
  [ swap >>total-mines swap >>dim swap >>cells ] 3bi
  dup <finish-arrow> >>finished?
  f <model> >>start ; inline

: all-indices ( dim -- indices ) [ ] <matrix*> concat ;
: random-indices ( dim mines -- indices )
  [ drop all-indices ] [ nip sample ] 2bi ;
: random-matrix ( dim mines -- matrix )
  dupd random-indices [ member? ] curry <matrix*> ;
: random-cells ( dim mines grid -- cells )
  [ random-matrix ] [ 
    '[ swap _ <minecell> ] mmap-index
  ] bi* ;
: <random-grid> ( dim mines -- grid ) [ random-cells ] <grid> ;
: <empty-grid> ( dim -- grid ) 0 <random-grid> ;
