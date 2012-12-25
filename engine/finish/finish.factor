! Copyright (C) 2012 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors combinators.short-circuit kernel sequences
sequences.extras minesweeper.engine.types ;
IN: minesweeper.engine.finish

<PRIVATE
: cleared-all? ( cells -- ? )
  [ [ mined?>> not ] [ cleared?>> value>> not ] bi and ] none? ;
: marked-all? ( cells -- ? )
  [ [ mined?>> ] [ marked?>> value>> not ] bi and ] none? ;
: won? ( seq -- ? ) { [ cleared-all? ] [ marked-all? ] } 1&& ;
: lost? ( grid -- ? )
  [ [ mined?>> ] [ cleared?>> value>> ] bi and ] any? ;
PRIVATE>

: finished? ( grid -- won? finished? )
  cells>> concat [ won? ] [ lost? ] bi [ drop ] [ or ] 2bi ;
