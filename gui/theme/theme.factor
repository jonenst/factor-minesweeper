! Copyright (C) 2012 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors colors colors.constants combinators fonts
io.pathnames kernel locals math math.order sequences
ui.gadgets.buttons ui.images ui.pens ui.pens.image ;
IN: minesweeper.gui.theme

: minesweeper-image-pen ( string -- path )
  "vocab:minesweeper/" prepend-path ".png" append <image-name> <image-pen> ;
: minecell-theme ( gadget -- gadget )
  "cell-plain" minesweeper-image-pen dup
  "cell-pressed" minesweeper-image-pen dup dup <button-pen> >>interior
  dup dup interior>> pen-pref-dim >>min-dim { 10 0 } >>size ;

CONSTANT: BOOM "X"
CONSTANT: MARK "!"
CONSTANT: MISSED-MINE "@"

CONSTANT: number-colors {
  COLOR: blue
  COLOR: DarkGreen
  COLOR: red
}

