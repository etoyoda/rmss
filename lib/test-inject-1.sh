#!/bin/sh

sock=/tmp/rmss.test1.sock

ruby -I. rmss-print.rb file://${sock} &
echo foo | ruby -I. rmss-inject.rb file://${sock}
wait
