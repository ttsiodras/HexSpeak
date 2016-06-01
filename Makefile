TARGET=target/uberjar/thanassis-0.1.0-SNAPSHOT-standalone.jar

ifndef VERBOSE
    .SILENT:
endif

EXPECT:=$(shell command -v expect 2>/dev/null)
GREP:=$(shell command -v grep 2>/dev/null)
AWK:=$(shell command -v awk 2>/dev/null)
BASH:=$(shell command -v bash 2>/dev/null)
LEIN:=$(shell command -v lein 2>/dev/null)
JAVA:=$(shell command -v java 2>/dev/null)
JAVAC:=$(shell command -v javac 2>/dev/null)

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
ifndef AWK
	$(error "You appear to be missing the 'awk' utility...")
endif
ifndef BASH
	$(error "You appear to be missing the 'bash' shell...")
endif
	@echo "All tools are there, proceeding..."


contrib/hexspeak.class:	contrib/hexspeak.java
ifndef JAVAC
	$(error "You appear to be missing the 'javac' from the JDK...")
endif
	cd contrib ; javac hexspeak.java


bench:	| ${TARGET} checkBenchDeps contrib/hexspeak.class
	$(MAKE) benchPython
	$(MAKE) benchClojure
	$(MAKE) benchPyPy
	$(MAKE) benchJava
	$(MAKE) benchCPP


benchPython:
	@echo
	@echo "Benchmarking Python (best out of 10 executions)..."
	@bash -c "for i in {1..10} ; do ./contrib/hexspeak.py 14 abcdef contrib/words ; done" | awk '{print $$3; fflush();}' | contrib/stats.py | grep Min
	@echo


benchPyPy:
	@echo
	@echo "Benchmarking PyPy (best out of 10 executions)..."
	@bash -c "for i in {1..10} ; do pypy ./contrib/hexspeak.py 14 abcdef contrib/words ; done" | awk '{print $$3; fflush();}' | contrib/stats.py | grep Min
	@echo


benchClojure:	| ${TARGET}
ifndef JAVA
	$(error "You appear to be missing the 'java' JRE...")
endif
	@echo
	@echo "Benchmarking Clojure (best out of 10 executions)..."
	@java -jar ${TARGET} 14 abcdef contrib/words | grep --line-buffered Elapsed | awk '{print $$3; fflush();}' | contrib/stats.py | grep Min
	@echo


benchJava:	contrib/hexspeak.class
ifndef JAVA
	$(error "You appear to be missing the 'java' JRE...")
endif
	@echo
	@echo "Benchmarking Java (best out of 10 executions)..."
	@cd contrib ; java hexspeak | awk '{print $$3; fflush();}' | ./stats.py | grep Min
	@echo


contrib/HexSpeak-C++/bin.release/hexspeak:	contrib/HexSpeak-C++/src/hexspeak.cpp
	$(MAKE) -C contrib/HexSpeak-C++/ CFG=release

benchCPP:	contrib/HexSpeak-C++/bin.release/hexspeak
	@echo
	@echo "Benchmarking C++ (best out of 10 executions)..."
	@cd contrib/HexSpeak-C++/bin.release/ ; ./hexspeak | awk '{print $$3; fflush();}' | ../../stats.py | grep Min
	@echo
	

test:	| ${TARGET}
ifndef EXPECT
	$(error "The 'expect' utility appears to be missing...")
endif
	@echo Testing...
	@./contrib/verifyResultFor14.expect | grep -v --line-buffered Elapsed | grep -v --line-buffered 3020796


clean:
	rm -rf ${TARGET} target contrib/hexspeak.class

.PHONY:	bench clean test bench benchPython benchPyPy benchClojure benchJava
