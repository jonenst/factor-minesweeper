! Copyright (C) 2012 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors eval kernel literals math math.matrices
minesweeper.engine models prettyprint prettyprint.config
sequences sorting tools.test ;
IN: minesweeper.engine.tests

CONSTANT: m {
  { 0 1 2 }
  { 3 4 5 }
  { 6 7 8 }
}

: deep-clone ( obj -- obj' )
  [ unparse ] without-limits eval( -- el ) ;

{ 0 } [ { 0 0 } m Mi,j ] unit-test
{ 5 } [ { 1 2 } m Mi,j ] unit-test

{ 12 } [ 12 { 1 2 } m deep-clone [ Mi,j! ] [ Mi,j ] 2bi ] unit-test

{ $ m } [ 3 3 zero-matrix [ nip first2 [ 3 * ] [ + ] bi* ] mmap-index ] unit-test

{ { { 0 1 } { 1 0 } { 1 1 } } } [ { 0 0 } { 3 3 } neighbours natural-sort ] unit-test
{ { { 1 1 } { 1 2 } { 2 1 } } } [ { 2 2 } { 3 3 } neighbours natural-sort ] unit-test

CONSTANT: empty-grid $[ { 3 3 } <empty-grid> ]
{ $[ 3 3 zero-matrix ] } [ empty-grid cells>> [ drop neighbour-mines ] mmap-index ] unit-test


: <test-grid> ( -- grid )
  { 3 3 } <empty-grid> [
    cells>> { 1 1 } swap Mi,j mined?>> t swap set-model
  ] keep ;
CONSTANT: test-grid $ <test-grid>

{ $[
  3 3 zero-matrix [ 2drop 1 ] mmap-index
  [ [ 0 { 1 1 } ] dip Mi,j! ] keep
] } [ test-grid cells>> [ drop neighbour-mines ] mmap-index ] unit-test

{ $[
  3 3 zero-matrix [ 2drop f ] mmap-index [
    [ t { 0 0 } ] dip Mi,j!
  ] keep
] } [ <test-grid> cells>> [ { 0 0 } swap Mi,j demine-cell ] [ [ drop cleared?>> value>> ] mmap-index ] bi ] unit-test

{ $[
  3 3 zero-matrix [ 2drop f ] mmap-index [
    [ t { 1 1 } ] dip Mi,j!
  ] keep
] } [ <test-grid> cells>> [ { 1 1 } swap Mi,j demine-cell ] [ [ drop cleared?>> value>> ] mmap-index ] bi ] unit-test

{ $[
  3 3 zero-matrix [ 2drop t ] mmap-index
] } [ { 3 3 } <empty-grid> cells>> [ { 0 0 } swap Mi,j demine-cell ] [ [ drop cleared?>> value>> ] mmap-index ] bi ] unit-test

{ t t } [ { 3 3 } <empty-grid> dup finished?>> activate-model
  [ cells>> { 0 0 } swap Mi,j demine-cell ]
  [ [ won?>> ] [ finished?>> value>> ] bi ] bi
] unit-test
{ f t } [ <test-grid> dup finished?>> activate-model 
  [ cells>> { 1 1 } swap Mi,j demine-cell ]
  [ [ won?>> ] [ finished?>> value>> ] bi ] bi
] unit-test
{ f } [ <test-grid> dup finished?>> activate-model
  [ cells>> { 0 0 } swap Mi,j demine-cell ]
  [ finished?>> value>> ] bi
] unit-test

{ 3 } [ { 3 3 } 3 <random-grid> cells>> concat [ first demine-cell ] [ [ mined?>> value>> ] count ] bi ] unit-test
{ 5 } [ { 5 5 } 5 <random-grid> cells>> concat [ first demine-cell ] [ [ mined?>> value>> ] count ] bi ] unit-test

{ f } [ <test-grid> cells>> [ { 0 0 } swap Mi,j demine-cell ] [ { 0 1 } swap Mi,j marked?>> value>> ] bi ] unit-test
: (clear-cells) ( cells -- clear-cells )
  [ drop dup mined?>> value>> [ drop f ] when ] mmap-index concat sift ;
: clear-cells ( cells -- )
  (clear-cells) [ demine-cell ] each ;
{ t } [ <test-grid> cells>> [ clear-cells ] [ { 1 1 } swap Mi,j marked?>> value>> ] bi ] unit-test
