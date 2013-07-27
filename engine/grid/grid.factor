! Copyright (C) 2012 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays minesweeper.engine.types
fry kernel minesweeper.engine.finish
minesweeper.engine minesweeper.matrix-utils models models.arrow
models.product random sequences ;
IN: minesweeper.engine.grid

<PRIVATE
: <cells-model> ( cells -- model )
  cells>> concat [ cleared?>> ] [ marked?>> ] [ map <product> ] bi-curry@ bi 2array <product> ;

: check-finished ( grid -- finished? )
  dup finished? [ >>won? drop ] dip ;
: <finish-arrow> ( cells-model grid -- arrow )
  [ nip check-finished ] curry <arrow> ;
: <started-arrow> ( cells-model grid -- arrow )
  [ nip cells>> concat [ cleared?>> value>> ] any? ] curry <arrow> ;
PRIVATE>

: new-grid ( dim mines quot: ( dim mines grid -- cells ) class -- grid )
  new swap
  [ swap >>total-mines swap >>dim swap >>cells ] 3bi
  dup
    [ <cells-model> ] keep
    [ <finish-arrow> >>finished? ]
    [ <started-arrow> >>started? ] 2bi ; inline

<PRIVATE
: all-indices ( dim -- indices ) [ ] <matrix*> concat ;
: random-indices ( dim mines -- indices )
  [ all-indices ] [ sample ] bi* ;
: random-matrix ( dim mines -- matrix )
  dupd random-indices [ member? ] curry <matrix*> ;
: random-cells ( dim mines grid -- cells )
  [ random-matrix ] [
    '[ swap _ <minecell> ] mmap-index
  ] bi* ;
PRIVATE>

: new-random-grid ( dim mines class -- grid )
  [ random-cells ] swap new-grid ; inline
: new-empty-grid ( dim class -- grid )
  0 swap new-random-grid ; inline
