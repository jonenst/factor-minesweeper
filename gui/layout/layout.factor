! Copyright (C) 2012 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: kernel ui.gadgets ;
IN: minesweeper.gui.layout

: info-container ( toplevel -- child ) gadget-child 1 swap nth-gadget ;
: info-gadget ( toplevel -- child ) info-container 1 swap nth-gadget ;
: minegrid-container ( toplevel -- child ) ;
: minegrid-gadget ( toplevel -- child ) minegrid-container 1 swap nth-gadget ;
