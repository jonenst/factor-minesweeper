! Copyright (C) 2012 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays kernel math math.order math.ranges
math.vectors minesweeper.matrix-utils sequences
sequences.product minesweeper.engine.grid ;
IN: minesweeper.engine.neighbours

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
