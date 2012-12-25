! Copyright (C) 2012 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors calendar kernel math minesweeper.engine
minesweeper.engine.grid models models.arrow sequences timers 
minesweeper.engine.types ;
FROM: models => change-model ;
IN: minesweeper.engine.timed-grid

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
