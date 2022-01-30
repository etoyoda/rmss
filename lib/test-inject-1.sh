#!/bin/sh

sock=/tmp/rmss.test1.sock

ruby -I. rmss-print.rb -debug -once file://${sock} &
sleep 1
echo foo | ruby -I. rmss-inject.rb -debug file://${sock}
wait
