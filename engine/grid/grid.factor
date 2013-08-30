! Copyright (C) 2012 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays minesweeper.engine.types
fry kernel minesweeper.engine.finish
minesweeper.engine minesweeper.matrix-utils models models.arrow
models.product random sequences minesweeper.atomic-products ;
IN: minesweeper.engine.grid

<PRIVATE
: <cells-model> ( cells -- model )
  cells>> concat [ cleared?>> ] [ marked?>> ] [ map <atomic-product> ] bi-curry@ bi 2array <atomic-product> ;

: check-finished ( grid -- finished? )
  dup finished? [ >>won? drop ] dip ;
: <finish-arrow> ( cells-model grid -- arrow )
  [ nip check-finished ] curry <arrow> ;
: <started-arrow> ( cells-model grid -- arrow )
  [ nip cells>> concat [ cleared?>> value>> ] any? ] curry <arrow> ;
: <cell-matrix> ( dim grid -- cells )
  [ <minecell> ] curry <matrix*> ;
PRIVATE>

: new-grid ( dim mines quot: ( {i,j} dim mines -- indices ) class -- grid )
  new swap >>init-mines-quot
  [ nip <cell-matrix> ]
  [ swap >>total-mines swap >>dim swap >>cells ] 3bi
  dup
    [ <cells-model> ] keep
    [ <finish-arrow> >>finished? ]
    [ <started-arrow> >>started? ] 2bi ; inline

<PRIVATE
: all-indices ( {i,j} dim -- indices ) [ ] <matrix*> concat remove ;
: random-indices ( {i,j} dim mines -- indices )
  [ all-indices ] [ sample ] bi* ;
PRIVATE>

: new-random-grid ( dim mines class -- grid )
  [ random-indices ] swap new-grid ; inline
: new-empty-grid ( dim class -- grid )
  0 swap new-random-grid ; inline
: <empty-grid> ( dim -- grid ) \ grid new-empty-grid ;
: <random-grid> ( dim mines -- grid ) \ grid new-random-grid ;
