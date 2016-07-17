MAKEFILE_FOLDER:=$(shell pwd)

###################
# Use colors, Luke

NO_COLOR=\033[0m\n
GREEN=\033[32;01m
RED=\033[31;01m
YELLOW=\033[33;01m

all:	hylang hy bench

hylang:
	@printf "$(GREEN)Creating PyPy3-based local virtualenv...$(NO_COLOR)"
	virtualenv3 -p /usr/bin/pypy3 hylang

hy:	| hylang
	@printf "$(GREEN)Installing HyLang from GitHub in local virtualenv...$(NO_COLOR)"
	bash -c "cd ${MAKEFILE_FOLDER} && . ${MAKEFILE_FOLDER}/hylang/bin/activate && git clone https://github.com/hylang/hy.git && cd hy && python setup.py install"

hexspeak.py:	hexspeak.hy
	@printf "$(GREEN)Compiling Hy to Python (will install Hy from GitHub to local virtualenv)...$(NO_COLOR)"
	bash -c "cd ${MAKEFILE_FOLDER} && . ${MAKEFILE_FOLDER}/hylang/bin/activate && hy2py hexspeak.hy > foo.py"
	cat foo.py | sed 's,:G_1235,G_1235,g' > hexspeak.py

bench:	hexspeak.py | hylang hy
	@mkdir -p ../../results
	@printf "$(GREEN)Benchmarking Hy via PyPy (best out of 10 executions)...$(NO_COLOR)"
	@bash -c "cd ${MAKEFILE_FOLDER} && . ${MAKEFILE_FOLDER}/hylang/bin/activate && for i in {1..10} ; do python hexspeak.py 14 abcdef ../words ; done" | awk '{print $$4; fflush();}' | tee ${MAKEFILE_FOLDER}/../../results/timings.hylang.txt | ${MAKEFILE_FOLDER}/../../contrib/stats.py | grep Min
