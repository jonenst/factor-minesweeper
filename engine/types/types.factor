! Copyright (C) 2012 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: kernel models ;
IN: minesweeper.engine.types

TUPLE: minecell idx mined? grid cleared? marked? ;
: <minecell> ( idx mined? grid -- minecell )
  f <model> f <model> \ minecell boa ;

TUPLE: grid dim cells total-mines started? finished? won? ;

