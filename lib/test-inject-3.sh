#!/bin/sh

sock=/tmp/rmss.test1.sock

host='[::]'

ruby -I. rmss-print.rb -once jmasock://${host}:3776/ &
sleep 1
echo foo | ruby -I. rmss-inject.rb jmasock://${host}:3776/
wait
