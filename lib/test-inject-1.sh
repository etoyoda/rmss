#!/bin/sh

sock=/tmp/rmss.test1.sock

test ! -S $sock || rm -f $sock
ruby -I. rmss-print.rb file://${sock} &
echo foo | ruby -I. rmss-inject.rb file://${sock}
wait
