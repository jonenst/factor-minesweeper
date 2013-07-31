! Copyright (C) 2012 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors colors colors.constants combinators fonts
io.pathnames kernel locals math math.order
minesweeper.gui.theme sequences ui.gadgets.buttons ui.images
ui.pens ui.pens.image ;
IN: minesweeper.gui.font

: base-font ( font -- font )
  t >>bold?  T{ rgba f 1 0 0 0 } font-with-background ;
: cleared-font ( n font -- font )
  base-font
  [ 1 - 0 2 clamp number-colors nth ]
  [ swap font-with-foreground ] bi* ;
: marked-font ( font -- font )
  base-font COLOR: black font-with-foreground ;
: false-positive-marked-font ( font -- font )
  base-font COLOR: red font-with-foreground ;
: correct-marked-font ( font -- font )
  base-font COLOR: DarkGreen font-with-foreground ;

: explosion-font ( font -- font )
  base-font COLOR: DarkRed font-with-foreground ;

:: minesweeper-font ( cleared? marked? mined? n finished? -- font )
  monospace-font {
    { [ cleared? mined? and ] [ explosion-font ] }
    { [ cleared? mined? not and ] [ n swap cleared-font ] }
    { [ marked? finished? not and ] [ marked-font ] }
    { [ marked? mined? and ] [ correct-marked-font ] }
    { [ marked? ] [ false-positive-marked-font ] }
    [ base-font ]
  } cond ;

