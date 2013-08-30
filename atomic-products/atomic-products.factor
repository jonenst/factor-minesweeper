! Copyright (C) 2013 Jon Harper.
! See http://factorcode.org/license.txt for BSD license.
USING: arrays fry kernel literals models models.product
namespaces sequences sets ;
FROM: models.product => product ;
IN: minesweeper.atomic-products

SYMBOL: triggerred-products
SYMBOL: updating?
TUPLE: atomic-product < product ;
: <atomic-product> ( models -- product ) atomic-product new-product ;
M: atomic-product model-changed ( model observer -- )
  updating? get
    [ nip triggerred-products get adjoin ]
    [ call-next-method ] if ;

: atomic-scope ( -- scope )
  { updating? t } 
  \ triggerred-products V{ } clone 2array 2array ;
: notify-products ( seq -- )
  [ f swap M\ product model-changed execute ] each ;
! FIXME, make this an inline recursive combinator
: with-atomic-products ( obj quot -- )
  [ atomic-scope ] dip '[ @ triggerred-products get ]
  [ call( x -- x ) ] curry with-variables
  [ [ notify-products ] with-atomic-products ] unless-empty ;
