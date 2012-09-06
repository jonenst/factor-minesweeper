! Copyright (C) 2012 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors kernel models sequences ;
IN: minesweeper.engine

TUPLE: minecell mined? selected guess ;
: <minecell> ( mined? -- minecell ) f <model> f <model> \ minecell boa ;

TUPLE: grid n m cells ;

: <example-grid> ( -- grid )
  \ grid new 3 >>n 3 >>m
  9 [ f <minecell> ] replicate >>cells ;
