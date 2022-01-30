#!/bin/sh

sock=/tmp/rmss.test1.sock

ruby -I. rmss-print.rb -debug -once jmasock://localhost:3776 &
sleep 1
echo foo | ruby -I. rmss-inject.rb -debug jmasock://localhost:3776
wait
