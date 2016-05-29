#!/bin/bash
mvn package || exit 1
java -jar target/benchmarks.jar \
     -f 1 -wi 5 -i 5 -r 3s \
     -jvmArgs '-server -XX:+AggressiveOpts' \
     .*Benchmark.*
