! Copyright (C) 2012 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays combinators.short-circuit fry kernel
math math.order math.ranges math.vectors models models.arrow
models.product random sequences sequences.extras
sequences.product ;
IN: minesweeper.engine

TUPLE: minecell idx mined? grid cleared? marked? ;
TUPLE: grid dim cells total-mines finished? won? ;

: cleared-all? ( cells -- ? )
  [ [ mined?>> not ] [ cleared?>> value>> not ] bi and ] none? ;
: marked-all? ( cells -- ? )
  [ [ mined?>> ] [ marked?>> value>> not ] bi and ] none? ;
: won? ( seq -- ? ) { [ cleared-all? ] [ marked-all? ] } 1&& ;
: lost? ( grid -- ? )
  [ [ mined?>> ] [ cleared?>> value>> ] bi and ] any? ;
: finished? ( grid -- won? finished? )
  cells>> concat [ won? ] [ lost? ] bi [ drop ] [ or ] 2bi ;

: <matrix> ( dim n -- matrix )
  [ first2 ] [ '[ _ [ _ ] replicate ] replicate ] bi* ;
: Mi,j ( idx M -- x )
  [ swap nth ] reduce ;
: Mi,js ( seq M -- seq )
  [ Mi,j ] curry map ;
: Mi,j! ( el idx M -- )
  [ first2 swap ] [ nth set-nth ] bi* ;
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
: neighbour-mines ( minecell -- n )
  [ idx>> ] [ grid>> ] bi
  [ dim>> neighbours ] [ nip cells>> ] 2bi
  Mi,js [ mined?>> ] count ;

DEFER: demine-cell
: ?demine-neighbours ( minecell -- )
  dup [ neighbour-mines zero? ] [ mined?>> not ] bi and [
    [ [ idx>> ] [ grid>> dim>> ] bi neighbours ]
    [ grid>> cells>> ] bi [
      Mi,j demine-cell
    ] curry each
  ] [ drop ] if ;
: demine-cell ( minecell -- )
  dup cleared?>> value>> [ drop ] [
    [ cleared?>> t swap set-model ]
    [ ?demine-neighbours ] bi
  ] if ;

: <minecell> ( idx mined? grid -- minecell )
  f <model> f <model> \ minecell boa ;


: check-finished ( grid -- finished? )
  dup finished? [ >>won? drop ] dip ;

: <finish-in-model> ( cells -- model )
  concat [ cleared?>> ] [ marked?>> ] [ map <product> ] bi-curry@ bi 2array <product> ;
: <finish-arrow> ( grid -- arrow )
  [ cells>> <finish-in-model> ]
  [ [ nip check-finished ] curry ] bi <arrow> ;
: <grid> ( dim mines quot: ( dim mines grid -- cells ) -- grid )
  [ \ grid new ] dip
  [ swap >>total-mines swap >>dim swap >>cells ] 3bi
  dup <finish-arrow> >>finished? ; inline

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
