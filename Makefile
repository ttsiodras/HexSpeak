TARGET=target/uberjar/thanassis-0.1.0-SNAPSHOT-standalone.jar

EXPECT:=$(shell command -v expect 2>/dev/null)
GREP:=$(shell command -v grep 2>/dev/null)
SED:=$(shell command -v sed 2>/dev/null)
TEE:=$(shell command -v tee 2>/dev/null)
BASH:=$(shell command -v bash 2>/dev/null)
LEIN:=$(shell command -v lein 2>/dev/null)

all:	${TARGET}

${TARGET}:	src/thanassis/hexspeak.clj
ifndef LEIN
	$(error "You appear to be missing the 'lein' builder (Leiningen)")
endif
	@lein uberjar

checkBenchDeps:
ifndef GREP
	$(error "You appear to be missing the 'grep' utility...")
endif
ifndef SED
	$(error "You appear to be missing the 'sed' utility...")
endif
ifndef TEE
	$(error "You appear to be missing the 'tee' utility...")
endif
ifndef BASH
	$(error "You appear to be missing the 'bash' shell...")
endif
	@echo "All tools are there, proceeding..."

bench:	| ${TARGET} checkBenchDeps
	$(MAKE) benchPython
	$(MAKE) benchJava
	$(MAKE) benchPyPy

benchPython:
	@echo Benchmarking Python...
	@bash -c "for i in {1..10} ; do bash -c 'time ./contrib/hexspeak.py 14 abcdef contrib/words' |& grep --line-buffered ^real | sed 's,s$$,,;s,^.*m,,' ; done" | tee /dev/stderr | contrib/stats.py
	@echo

benchPyPy:
	@echo Benchmarking PyPy...
	@bash -c "for i in {1..10} ; do bash -c 'time pypy ./contrib/hexspeak.py 14 abcdef contrib/words' |& grep --line-buffered ^real | sed 's,s$$,,;s,^.*m,,' ; done" | tee /dev/stderr | contrib/stats.py
	@echo

benchJava:	| ${TARGET}
	@echo Benchmarking Java...
	@bash -c "java -jar ${TARGET} 14 abcdef contrib/words | grep --line-buffered Elapsed | awk '{print \$$3; fflush();}' | tee /dev/stderr | contrib/stats.py"
	@echo

test:	| ${TARGET}
ifndef EXPECT
	$(error "The 'expect' utility appears to be missing...")
endif
	@echo Testing...
	@./contrib/verifyResultFor14.expect

clean:
	rm -rf ${TARGET} target

.PHONY:	bench clean test bench benchPython benchPyPy benchJava
