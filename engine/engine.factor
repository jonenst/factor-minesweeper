! Copyright (C) 2012 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays kernel locals math math.matrices
math.order math.ranges math.vectors models random sequences
sequences.product sets ;
IN: minesweeper.engine

TUPLE: minecell selected guess idx mined? grid ;
TUPLE: grid dim cells total-mines finished loss ;

: update-finish-model ( grid loss? -- )
  >>loss finished>> t swap set-model ;
: ?update-finish-model ( grid loss? finished? -- )
  [ update-finish-model ] [ 2drop ] if ;
: won? ( seq -- ? )
  [ [ mined?>> not ] [ selected>> value>> not ] bi and ] any? not ;
: lost? ( grid -- ? )
  [ [ mined?>> ] [ selected>> value>> ] bi and ] any? ;
: finished? ( grid -- loss? ? )
  [ cells>> concat [ won? ] [ lost? ] bi [ nip ] [ or ] 2bi ]
  [ -rot [ ?update-finish-model ] 2keep ] bi ;

: Mi,j ( idx M -- x )
  [ swap nth ] reduce ;
: Mi,js ( seq M -- seq )
  [ Mi,j ] curry map ;
: Mi,j! ( el idx M -- )
  [ first2 swap ] [ nth set-nth ] bi* ;
: mmap-index ( ... M quot: ( ... el idx -- ... el ) -- ... )
  [ [ [ swap 2array ] prepose call ] curry curry map-index ] curry map-index ; inline

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
    [ [ idx>> ] [ grid>> dim>> ] bi neighbours ] [ grid>> cells>> ] bi [
      Mi,j demine-cell
    ] curry each
  ] [ drop ] if ;
: demine-cell ( minecell -- )
  dup selected>> value>> [ drop ] [
    [ selected>> t swap set-model ]
    [ ?demine-neighbours ] bi
  ] if ;

: <minecell> ( idx mined? grid -- minecell )
  [ f <model> f <model> ] 3dip \ minecell boa ;

: <grid> ( finish-model dim mines quot: ( dim mines grid -- cells ) -- grid )
  [ \ grid new ] dip
  [ swap >>total-mines swap >>dim swap >>cells swap >>finished ] 3bi ; inline

:: empty-cells ( dim grid -- cells )
  dim first2 zero-matrix [ nip f grid <minecell> ] mmap-index ;
: <empty-grid> ( dim -- grid )
  [ f <model> ] dip 0 [ nip empty-cells ] <grid> ;

: random-indices ( dim mines -- indices )
  [ drop first2 zero-matrix [ nip ] mmap-index concat ] [ nip sample ] 2bi ;
: random-matrix ( dim mines -- matrix )
  [ drop first2 zero-matrix ] [ random-indices ] 2bi
  [ in? nip ] curry mmap-index ;
:: random-cells ( dim mines grid -- cells )
  dim mines random-matrix
  [ swap grid <minecell> ] mmap-index ;
: <random-grid> ( finish-model dim mines -- grid )
  [ random-cells ] <grid> ;
