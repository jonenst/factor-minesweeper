! Copyright (C) 2012 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors arrays calendar combinators.short-circuit fry
kernel math math.order math.ranges math.vectors models
models.arrow models.product random sequences sequences.extras
sequences.product timers ;
FROM: models => change-model ;
FROM: sequences => product ;
IN: minesweeper.engine

TUPLE: minecell idx mined? grid cleared? marked? ;
TUPLE: grid dim cells total-mines started? finished? won? ;

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

: <cells-model> ( cells -- model )
  cells>> concat [ cleared?>> ] [ marked?>> ] [ map <product> ] bi-curry@ bi 2array <product> ;
: <finish-arrow> ( cells-model grid -- arrow )
  [ nip check-finished ] curry <arrow> ;
: <started-arrow> ( cells-model grid -- arrow )
  [ nip cells>> concat [ cleared?>> value>> ] any? ] curry <arrow> ;

: demine-mark ( minecell -- )
  [ (demine-cell) ]
  [ mark-obvious-cells ]
  [ ?mark-remaining ] tri ;
: demine-cell ( minecell -- ) demine-mark ;
: toggle-model ( model -- ) [ not ] change-model ;
: toggle-mark ( minecell -- ) marked?>> toggle-model ;
: ?expand-cell ( minecell -- )
  dup cleared?>> value>> [
    neighbour-cells dup [ mines-count ] [ marked-count ] bi = [
      [ marked?>> value>> not ] filter [ demine-cell ] each
    ] [ drop ] if
  ] [ drop ] if ;

: new-grid ( dim mines quot: ( dim mines grid -- cells ) class -- grid )
  new swap
  [ swap >>total-mines swap >>dim swap >>cells ] 3bi
  dup
    [ <cells-model> ] keep
    [ <finish-arrow> >>finished? ]
    [ <started-arrow> >>started? ] 2bi ; inline

: all-indices ( dim -- indices ) [ ] <matrix*> concat ;
: random-indices ( dim mines -- indices )
  [ drop all-indices ] [ nip sample ] 2bi ;
: random-matrix ( dim mines -- matrix )
  dupd random-indices [ member? ] curry <matrix*> ;
: random-cells ( dim mines grid -- cells )
  [ random-matrix ] [
    '[ swap _ <minecell> ] mmap-index
  ] bi* ;
: new-random-grid ( dim mines class -- grid )
  [ random-cells ] swap new-grid ; inline
: new-empty-grid ( dim class -- grid )
  0 swap new-random-grid ; inline

TUPLE: timed-grid < grid duration timer callbacks ;

: <duration-updater> ( model -- timer )
  [ [ 1 + ] change-model ] curry 1 seconds delayed-every ;

: <callback> ( model quot -- arrow )
  [ f ] compose <arrow> dup activate-model ;
: add-callback ( grid callback-quot: ( grid -- callback ) -- )
  [ callbacks>> push ] bi ; inline
: ?start-duration-timer ( started? grid -- )
  swap not over timer>> or [ drop ] [
    dup duration>> <duration-updater> >>timer drop
  ] if ;
: <start-callback> ( grid -- arrow )
   [ started?>> ] [ [ ?start-duration-timer ] curry ] bi <callback> ;

: stop-duration-timer ( grid -- )
  [ timer>> stop-timer ] [ f >>timer drop ] bi ;
: ?stop-duration-timer ( finished? grid -- )
  swap over timer>> and [ stop-duration-timer ] [ drop ] if ;
: <stop-callback> ( grid -- arrow )
  [ finished?>> ] [ [ ?stop-duration-timer ] curry ] bi <callback> ;

: add-start-callback ( grid -- ) [ <start-callback> ] add-callback ;
: add-stop-callback ( grid -- ) [ <stop-callback> ] add-callback ;
: <timed-random-grid> ( dim mines -- grid )
  \ timed-grid new-random-grid
  0 <model> >>duration V{ } clone >>callbacks
  dup [ add-start-callback ] [ add-stop-callback ] bi ;
: stop-callbacks ( grid -- )
  callbacks>> [ deactivate-model ] each ;
