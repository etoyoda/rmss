#!/bin/sh

sock=/tmp/rmss.test1.sock

host='[::]'

ruby -I. rmss-print.rb -debug -once jmasock://${host}:3776/ &
sleep 1
echo foo | ruby -I. rmss-inject.rb -debug jmasock://${host}:3776/
wait
