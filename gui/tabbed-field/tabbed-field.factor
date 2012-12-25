! Copyright (C) 2012 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: accessors kernel math math.order sequences
sequences.extras ui.commands ui.gadgets ui.gadgets.editors
ui.gestures ;
IN: minesweeper.gui.tabbed-field

TUPLE: tabbed-model-field < model-field prev next ;
: <tabbed-model-field> ( model -- gadget )
  tabbed-model-field new-field swap >>field-model ;

: com-next ( gadget -- ) next>> editor>> request-focus ;
: com-prev ( gadget -- ) prev>> editor>> request-focus ;
\ tabbed-model-field "editing" f {
  { T{ key-down f f "TAB" } com-next }
  { T{ key-down f { S+ } "TAB" } com-prev }
} define-command-map


: find-children ( gadget quot: ( child -- ? ) -- children )
  [ dupd call [ drop f ] unless ]
  [ [ children>> ] dip [ find-children ] curry map concat ] 2bi
  swap prefix sift ; inline recursive

: link-tabbed-gadget ( prev cur next -- ) >>next prev<< ;
: link-tabbed-gadgets ( tabbed-gadgets -- )
  [ dup length 1 - 0 max rotate ] [ ] [ dup length 1 - 0 1 clamp rotate ] tri
  [ link-tabbed-gadget ] 3each ;
: link-all-tabbed-gadgets ( gadget -- )
  [ tabbed-model-field? ] find-children link-tabbed-gadgets ;
