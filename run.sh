#!/bin/bash
make >/dev/shm/err 2>&1 || { cat /dev/shm/err ; rm /dev/shm/err ; exit 1 ; }
if [ $# -eq 0 ] ; then
    java -jar ./target/uberjar/thanassis-0.1.0-SNAPSHOT-standalone.jar 14 abcdef contrib/words
else
    java -jar ./target/uberjar/thanassis-0.1.0-SNAPSHOT-standalone.jar "$@"
fi
