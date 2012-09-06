! Copyright (C) 2012 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors kernel models sequences math.matrices math.ranges ;
IN: minesweeper.engine

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

TUPLE: minecell selected guess idx mined? grid ;
: <minecell> ( idx mined? grid -- minecell )
  [ f <model> f <model> ] 3dip \ minecell boa ;

TUPLE: grid dim cells ;

:: empty-cells ( dim grid -- cells )
  dim first2 zero-matrix [ nip f grid <minecell> ] mmap-index ;
: <empty-grid> ( dim -- grid )
  \ grid new [ empty-cells ] [ swap >>dim swap >>cells ] 2bi ;



