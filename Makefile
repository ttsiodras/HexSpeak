TARGET=target/uberjar/thanassis-0.1.0-SNAPSHOT-standalone.jar

all:	${TARGET}

${TARGET}:	src/thanassis/hexspeak.clj
	@lein uberjar

bench:	benchPython benchJava benchPyPy

benchPython:
	@echo Benchmarking Python...
	@bash -c "for i in {1..10} ; do bash -c 'time ./contrib/hexspeak.py abcdef 14' |& grep --line-buffered ^real | sed 's,s$$,,;s,^.*m,,' ; done" | tee /dev/stderr | stats.py 
	@echo

benchPyPy:
	@echo Benchmarking PyPy...
	@bash -c "for i in {1..10} ; do bash -c 'time pypy ./contrib/hexspeak.py abcdef 14' |& grep --line-buffered ^real | sed 's,s$$,,;s,^.*m,,' ; done" | tee /dev/stderr | stats.py 
	@echo

benchJava:	| ${TARGET}
	@echo Benchmarking Java...
	@bash -c "java -jar ${TARGET} 14 abcdef | grep --line-buffered Elapsed | awk '{print \$$3; fflush();}' | tee /dev/stderr | stats.py"
	@echo

test:	| ${TARGET}
	@echo Testing...
	@./contrib/verifyResultFor14.expect

clean:
	rm -rf ${TARGET} target

.PHONY:	bench clean test bench benchPython benchPyPy benchJava
