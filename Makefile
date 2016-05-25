TARGET=target/uberjar/thanassis-0.1.0-SNAPSHOT-standalone.jar

all:	${TARGET}

${TARGET}:	src/thanassis/core.clj
	@lein uberjar

bench:	| ${TARGET}
	@echo Benchmarking...
	@bash -c "java -jar ${TARGET} 14 abcdef | grep --line-buffered Elapsed | awk '{print \$$3; fflush();}' | tee /dev/stderr | stats.py"

test:	| ${TARGET}
	@echo Testing...
	@./contrib/verifyResultFor14.expect

clean:
	rm -f ${TARGET}

.PHONY:	bench clean test
