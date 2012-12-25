! Copyright (C) 2012 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: arrays fry kernel sequences ;
IN: minesweeper.matrix-utils

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

