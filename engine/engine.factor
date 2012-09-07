! Copyright (C) 2012 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays kernel locals math math.matrices
math.order math.ranges math.vectors models sequences
sequences.product ;
IN: minesweeper.engine

TUPLE: minecell selected guess idx mined? grid ;
TUPLE: grid dim cells ;

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
  Mi,js [ mined?>> ] filter length ;

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

:: empty-cells ( dim grid -- cells )
  dim first2 zero-matrix [ nip f grid <minecell> ] mmap-index ;
: <empty-grid> ( dim -- grid )
  \ grid new [ empty-cells ] [ swap >>dim swap >>cells ] 2bi ;

