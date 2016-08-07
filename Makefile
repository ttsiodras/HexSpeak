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
TEE:=$(shell command -v tee 2>/dev/null)
GREP:=$(shell command -v grep 2>/dev/null)
AWK:=$(shell command -v awk 2>/dev/null)
BASH:=$(shell command -v bash 2>/dev/null)
LEIN:=$(shell command -v lein 2>/dev/null)
JAVA:=$(shell command -v java 2>/dev/null)
JAVAC:=$(shell command -v javac 2>/dev/null)
SCALAC:=$(shell command -v scalac 2>/dev/null)
SCALA:=$(shell command -v scala 2>/dev/null)
GXX:=$(shell command -v g++ 2>/dev/null)
PYTHON3:=$(shell command -v python3 2>/dev/null)
PYPY3:=$(shell command -v pypy3 2>/dev/null)
VIRTUALENV3:=$(shell command -v virtualenv3 --version 2>/dev/null)
SHEDSKIN:=$(shell which shedskin 2>/dev/null)

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


#############################################
# And we also compared performance with Scala

TARGET_SCALA=contrib/Scala/HexSpeak.class

${TARGET_SCALA}:	contrib/Scala/hexspeak.scala
ifndef SCALAC
	$(error "You appear to be missing the 'scalac' compiler...")
endif
	@printf "$(GREEN)Compiling Scala code...$(NO_COLOR)"
	cd contrib/Scala/ ; scalac -optimize hexspeak.scala


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

########################
# And also with Shedskin

TARGET_SHEDSKIN_DIR=contrib/shedskin-compile-to-native
TARGET_SHEDSKIN=${TARGET_SHEDSKIN_DIR}/hexspeak
SHEDSKIN_SRC=contrib/shedskin-compile-to-native/hexspeak.cpp

${TARGET_SHEDSKIN}:	${SHEDSKIN_SRC}
ifndef GXX
	$(error "You appear to be missing 'g++' (C++ compiler)")
endif
	@printf "$(GREEN)Compiling ShedSkin C++ code...$(NO_COLOR)"
	$(MAKE) -C ${TARGET_SHEDSKIN_DIR}

${SHEDSKIN_SRC}:	contrib/hexspeak.py
	@printf "$(GREEN)Creating C++ code via ShedSkin...$(NO_COLOR)"
	@cd contrib/shedskin-compile-to-native/ && shedskin hexspeak.py

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
ifndef TEE
	$(error "You appear to be missing 'tee'...")
endif
ifndef PYTHON3
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
ifdef SHEDSKIN
	$(MAKE) ${TARGET_SHEDSKIN}
endif
endif

#
# ...then, run them:
#

ifdef GXX
	$(MAKE) benchCPP
else
	@printf "$(YELLOW)You are missing 'g++' - skipping C++ benchmark...$(NO_COLOR)"
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
ifdef SCALAC
ifdef SCALA
	$(MAKE) benchScala
else
	@printf "$(YELLOW)You are missing 'scala' - skipping Scala benchmark...$(NO_COLOR)"
endif
else
	@printf "$(YELLOW)You are missing 'scalac' - skipping Scala benchmark...$(NO_COLOR)"
endif
ifdef SHEDSKIN
	$(MAKE) benchShedSkin
else
	@printf "$(YELLOW)You are missing 'ShedSkin' - skipping ShedSkin benchmark...$(NO_COLOR)"
endif
ifdef PYPY3
	$(MAKE) benchPyPy
else
	@printf "$(YELLOW)You are missing 'pypy3' - skipping PyPy benchmark...$(NO_COLOR)"
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
ifdef PYPY3
ifdef VIRTUALENV3
	$(MAKE) benchHyLang
else
	@printf "$(YELLOW)You are missing 'virtualenv3' - skipping HyLang benchmark...$(NO_COLOR)"
endif
else
	@printf "$(YELLOW)You are missing 'pypy3' - skipping HyLang benchmark...$(NO_COLOR)"
endif
ifdef PYTHON3
	$(MAKE) benchPython
else
	@printf "$(YELLOW)You are missing 'python2' - skipping Python benchmark...$(NO_COLOR)"
endif

###############################################
# All the language-specific benchmarking logic 

benchPython:
	@mkdir -p results
	@echo
	@printf "$(GREEN)Benchmarking Python (best out of 10 executions)...$(NO_COLOR)"
	@bash -c "for i in {1..10} ; do ./contrib/hexspeak.py 14 abcdef contrib/words ; done" | awk '{print $$3; fflush();}' | tee results/timings.python.txt | contrib/stats.py | grep Min
	@echo


benchShedSkin:	| ${TARGET_SHEDSKIN}
	@mkdir -p results
	@echo
	@printf "$(GREEN)Benchmarking ShedSkin (best out of 10 executions)...$(NO_COLOR)"
	@bash -c "for i in {1..10} ; do ${TARGET_SHEDSKIN} 14 abcdef contrib/words ; done" | awk '{print $$3; fflush();}' | tee results/timings.shedskin.txt | contrib/stats.py | grep Min
	@echo


benchPyPy:
	@mkdir -p results
	@echo
	@printf "$(GREEN)Benchmarking PyPy (best out of 10 executions)...$(NO_COLOR)"
	@bash -c "for i in {1..10} ; do pypy3 ./contrib/hexspeak.py 14 abcdef contrib/words ; done" | awk '{print $$3; fflush();}' | tee results/timings.pypy.txt | contrib/stats.py | grep Min
	@echo


benchClojure:	| ${TARGET_CLOJURE}
ifndef JAVA
	$(error "You appear to be missing the 'java' JRE...")
endif
	@mkdir -p results
	@echo
	@printf "$(GREEN)Benchmarking Clojure (best out of 10 executions)...$(NO_COLOR)"
	@java -jar ${TARGET_CLOJURE} 14 abcdef contrib/words | grep --line-buffered Elapsed | awk '{print $$3; fflush();}' | tee results/timings.clojure.txt | contrib/stats.py | grep Min
	@echo
	@echo


benchJava:	${TARGET_JAVA}
ifndef JAVA
	$(error "You appear to be missing the 'java' JRE...")
endif
	@mkdir -p results
	@echo
	@printf "$(GREEN)Benchmarking Java (best out of 10 executions)...$(NO_COLOR)"
	@cd contrib ; java hexspeak | awk '{print $$3; fflush();}' | tee ../results/timings.java.txt | ./stats.py | grep Min
	@echo


benchScala:	${TARGET_SCALA}
ifndef SCALA
	$(error "You appear to be missing 'scala'...")
endif
	@mkdir -p results
	@echo
	@printf "$(GREEN)Benchmarking Scala (best out of 10 executions)...$(NO_COLOR)"
	@cd contrib/Scala ; scala HexSpeak | awk '{print $$3; fflush();}' | tee ../../results/timings.scala.txt | ../stats.py | grep Min
	@echo


benchCPP:	${TARGET_CPP}
	@mkdir -p results
	@echo
	@printf "$(GREEN)Benchmarking C++ (best out of 10 executions)...$(NO_COLOR)"
	@cd ${TARGET_CPP_DIR} ; pwd ; ./hexspeak | awk '{print $$3; fflush();}' | tee ../../../results/timings.cpp.txt | ../../stats.py | grep Min
	@echo

benchHyLang:
	@$(MAKE) -C contrib/HyLang
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
ifdef SCALAC
ifdef JAVA
	$(MAKE) ${TARGET_SCALA}
else
	@printf "$(YELLOW)You are missing 'java' - skipping Scala test...$(NO_COLOR)"
endif
else
	@printf "$(YELLOW)You are missing 'scalac' - skipping Scala test...$(NO_COLOR)"
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
ifdef SCALAC
ifdef JAVA
	@./test/verifyResultFor14_scala.expect | grep -v --line-buffered Elapsed | grep -v --line-buffered 3020796
endif
endif
ifdef GXX
	@./test/verifyResultFor14_cpp.expect | grep -v --line-buffered Elapsed | grep -v --line-buffered 3020796
endif
ifdef PYTHON3
	@./test/verifyResultFor14_cpython.expect | grep -v --line-buffered Elapsed | grep -v --line-buffered 3020796
else
	@printf "$(YELLOW)You are missing 'python2' - skipping Python test...$(NO_COLOR)"
endif
ifdef PYPY3
	@./test/verifyResultFor14_pypy.expect | grep -v --line-buffered Elapsed | grep -v --line-buffered 3020796
else
	@printf "$(YELLOW)You are missing 'pypy3' - skipping PyPy test...$(NO_COLOR)"
endif
ifdef SHEDSKIN
	@./test/verifyResultFor14_shedskin.expect | grep -v --line-buffered Elapsed | grep -v --line-buffered 3020796
else
	@printf "$(YELLOW)You are missing 'ShedSkin' - skipping ShedSkin test...$(NO_COLOR)"
endif

##############################
# Tukey Boxplot of the results
boxplot:	|bench
	cd contrib ; ./boxplot.py
	@printf "$(YELLOW)Generated contrib/boxplot.png$(NO_COLOR)"

###########
# Cleanup

clean:
	rm -rf ${TARGET_CLOJURE} ${TARGET_JAVA} contrib/Scala/*class
	$(MAKE) -C contrib/HexSpeak-C++/ CFG=release clean

.PHONY:	bench clean test benchPython benchPyPy benchClojure benchJava benchCPP
