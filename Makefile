ifndef VERBOSE
    .SILENT:
endif

###################
# Use colors, Luke

NO_COLOR=\033[0m\n
GREEN=\033[32;01m
RED=\033[31;01m
YELLOW=\033[33;01m

##################################################
# Detect the tools installed, to select benchmarks

EXPECT:=$(shell command -v expect 2>/dev/null)
GREP:=$(shell command -v grep 2>/dev/null)
AWK:=$(shell command -v awk 2>/dev/null)
BASH:=$(shell command -v bash 2>/dev/null)
LEIN:=$(shell command -v lein 2>/dev/null)
JAVA:=$(shell command -v java 2>/dev/null)
JAVAC:=$(shell command -v javac 2>/dev/null)
GXX:=$(shell command -v g++ 2>/dev/null)
PYTHON2:=$(shell command -v python2 2>/dev/null)
PYPY:=$(shell command -v pypy 2>/dev/null)

###########################################################
# This is a clojure experiment - that's our primary target:

TARGET_CLOJURE=target/uberjar/thanassis-0.1.0-SNAPSHOT-standalone.jar

all:	${TARGET_CLOJURE}

${TARGET_CLOJURE}:	src/thanassis/hexspeak.clj
ifndef LEIN
	$(error "You appear to be missing the 'lein' builder (Leiningen)")
endif
	@printf "$(GREEN)Compiling Clojure code...$(NO_COLOR)"
	@lein uberjar


#############################################
# But we also compared performance with Java

TARGET_JAVA=contrib/hexspeak.class

${TARGET_JAVA}:	contrib/hexspeak.java
ifndef JAVAC
	$(error "You appear to be missing the 'javac' from the JDK...")
endif
	@printf "$(GREEN)Compiling Java code...$(NO_COLOR)"
	cd contrib ; javac hexspeak.java


####################
# And also with C++

TARGET_CPP_DIR=contrib/HexSpeak-C++/bin.release
TARGET_CPP=${TARGET_CPP_DIR}/hexspeak

${TARGET_CPP}:	contrib/HexSpeak-C++/src/hexspeak.cpp
ifndef GXX
	$(error "You appear to be missing 'g++' (C++ compiler)")
endif
	@printf "$(GREEN)Compiling C++ code...$(NO_COLOR)"
	$(MAKE) -C contrib/HexSpeak-C++/ CFG=release


#############################################
# To perform any benchmarking, we need these

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
ifndef PYTHON2
	$(error "You appear to be missing 'python2'...")
endif


####################################################
# Adapt to using the benchmarks this machine can run
#
# First, compile those you can...
#
bench:	| checkBenchDeps
ifdef LEIN
ifdef JAVA
	$(MAKE) ${TARGET_CLOJURE}
endif
endif
ifdef JAVAC
ifdef JAVA
	$(MAKE) ${TARGET_JAVA}
endif
endif
ifdef GXX
	$(MAKE) ${TARGET_CPP}
endif

#
# ...then, run them:
#

ifdef PYTHON2
	$(MAKE) benchPython
else
	@printf "$(YELLOW)You are missing 'python2' - skipping Python benchmark...$(NO_COLOR)"
endif
ifdef LEIN
ifdef JAVA
	$(MAKE) benchClojure
else
	@printf "$(YELLOW)You are missing 'java' - skipping Clojure benchmark...$(NO_COLOR)"
endif
else
	@printf "$(YELLOW)You are missing 'lein' - skipping Clojure benchmark...$(NO_COLOR)"
endif
ifdef PYPY
	$(MAKE) benchPyPy
else
	@printf "$(YELLOW)You are missing 'pypy' - skipping PyPy benchmark...$(NO_COLOR)"
endif
ifdef JAVAC
ifdef JAVA
	$(MAKE) benchJava
else
	@printf "$(YELLOW)You are missing 'java' - skipping Java benchmark...$(NO_COLOR)"
endif
else
	@printf "$(YELLOW)You are missing 'javac' - skipping Java benchmark...$(NO_COLOR)"
endif
ifdef GXX
	$(MAKE) benchCPP
else
	@printf "$(YELLOW)You are missing 'g++' - skipping C++ benchmark...$(NO_COLOR)"
endif

###############################################
# All the language-specific benchmarking logic 

benchPython:
	@echo
	@printf "$(GREEN)Benchmarking Python (best out of 10 executions)...$(NO_COLOR)"
	@bash -c "for i in {1..10} ; do ./contrib/hexspeak.py 14 abcdef contrib/words ; done" | awk '{print $$3; fflush();}' | contrib/stats.py | grep Min
	@echo


benchPyPy:
	@echo
	@printf "$(GREEN)Benchmarking PyPy (best out of 10 executions)...$(NO_COLOR)"
	@bash -c "for i in {1..10} ; do pypy ./contrib/hexspeak.py 14 abcdef contrib/words ; done" | awk '{print $$3; fflush();}' | contrib/stats.py | grep Min
	@echo


benchClojure:	| ${TARGET_CLOJURE}
ifndef JAVA
	$(error "You appear to be missing the 'java' JRE...")
endif
	@echo
	@printf "$(GREEN)Benchmarking Clojure (best out of 10 executions)...$(NO_COLOR)"
	@java -jar ${TARGET_CLOJURE} 14 abcdef contrib/words | grep --line-buffered Elapsed | awk '{print $$3; fflush();}' | contrib/stats.py | grep Min
	@echo


benchJava:	${TARGET_JAVA}
ifndef JAVA
	$(error "You appear to be missing the 'java' JRE...")
endif
	@echo
	@printf "$(GREEN)Benchmarking Java (best out of 10 executions)...$(NO_COLOR)"
	@cd contrib ; java hexspeak | awk '{print $$3; fflush();}' | ./stats.py | grep Min
	@echo


benchCPP:	${TARGET_CPP}
	@echo
	@printf "$(GREEN)Benchmarking C++ (best out of 10 executions)...$(NO_COLOR)"
	@cd ${TARGET_CPP_DIR} ; ./hexspeak | awk '{print $$3; fflush();}' | ../../stats.py | grep Min
	@echo


########################################################################
# Tests - verifying that there are 3020796 hexspeak phrases of length 14

test:
ifndef EXPECT
	$(error "The 'expect' utility appears to be missing... Aborting tests.")
endif
ifdef LEIN
ifdef JAVA
	$(MAKE) ${TARGET_CLOJURE}
else
	@printf "$(YELLOW)You are missing 'java' - skipping Clojure test...$(NO_COLOR)"
endif
else
	@printf "$(YELLOW)You are missing 'lein' - skipping Clojure test...$(NO_COLOR)"
endif
ifdef JAVAC
ifdef JAVA
	$(MAKE) ${TARGET_JAVA}
else
	@printf "$(YELLOW)You are missing 'java' - skipping Java test...$(NO_COLOR)"
endif
else
	@printf "$(YELLOW)You are missing 'javac' - skipping Java test...$(NO_COLOR)"
endif
ifdef GXX
	$(MAKE) ${TARGET_CPP}
else
	@printf "$(YELLOW)You are missing 'g++' - skipping C++ test...$(NO_COLOR)"
endif
ifdef LEIN
ifdef JAVA
	@./test/verifyResultFor14_clojure.expect | grep -v --line-buffered Elapsed | grep -v --line-buffered 3020796
endif
endif
ifdef JAVAC
ifdef JAVA
	@./test/verifyResultFor14_java.expect | grep -v --line-buffered Elapsed | grep -v --line-buffered 3020796
endif
endif
ifdef GXX
	@./test/verifyResultFor14_cpp.expect | grep -v --line-buffered Elapsed | grep -v --line-buffered 3020796
endif
ifdef PYTHON2
	@./test/verifyResultFor14_cpython.expect | grep -v --line-buffered Elapsed | grep -v --line-buffered 3020796
else
	@printf "$(YELLOW)You are missing 'python2' - skipping Python test...$(NO_COLOR)"
endif
ifdef PYPY
	@./test/verifyResultFor14_pypy.expect | grep -v --line-buffered Elapsed | grep -v --line-buffered 3020796
else
	@printf "$(YELLOW)You are missing 'pypy' - skipping PyPy test...$(NO_COLOR)"
endif


###########
# Cleanup

clean:
	rm -rf ${TARGET_CLOJURE} ${TARGET_JAVA}
	$(MAKE) -C contrib/HexSpeak-C++/ CFG=release clean

.PHONY:	bench clean test benchPython benchPyPy benchClojure benchJava benchCPP
