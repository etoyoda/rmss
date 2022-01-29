#!/bin/sh

sock=/tmp/rmss.test1.sock

ruby -I. rmss-print.rb -once file://${sock} &
sleep 1
echo foo | ruby -I. rmss-inject.rb file://${sock}
wait
