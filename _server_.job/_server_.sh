#! /bin/sh
# This is an auto-generated Julia script for the Persist package
echo $$ >_server_.pid
/usr/local/Cellar/julia/0.4.2/bin/julia -Ccore2 -J/usr/local/Cellar/julia/0.4.2/lib/julia/sys.dylib -e using' Persist; Persist.runjob("_server_.bin", "_server_.res")' </dev/null >_server_.out 2>_server_.err
