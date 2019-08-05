MAKEFILE_FOLDER:=$(shell pwd)

###################
# Use colors, Luke

NO_COLOR=\033[0m\n
GREEN=\033[32;01m
RED=\033[31;01m
YELLOW=\033[33;01m

all:	bench

env:
	@printf "$(GREEN)Creating PyPy3-based local virtualenv...$(NO_COLOR)"
	bash -c "[ ! -d env ] && \
	    virtualenv3 -p /usr/bin/pypy3 env"
	# python3 -m virtualenv env"

hy:	| env
	@printf "$(GREEN)Installing HyLang from GitHub in local virtualenv...$(NO_COLOR)"
	bash -c "[ ! -d ${MAKEFILE_FOLDER}/hylang ] && \
	    cd ${MAKEFILE_FOLDER} && \
	    . ${MAKEFILE_FOLDER}/env/bin/activate && \
	    git clone https://github.com/hylang/hy.git && \
	    cd hy && \
	    pypy3 -m pip install --upgrade ."

hexspeak.py:	hexspeak.hy | hy
	@printf "$(GREEN)Compiling Hy to Python (will install Hy from GitHub to local virtualenv)...$(NO_COLOR)"
	bash -c "cd ${MAKEFILE_FOLDER} && \
	    . ${MAKEFILE_FOLDER}/env/bin/activate && \
	    hy2py hexspeak.hy > $@"

bench:	hexspeak.py
	@mkdir -p ../../results
	@printf "$(GREEN)Benchmarking Hy via PyPy (best out of 10 executions)...$(NO_COLOR)"
	@bash -c \
	    "cd ${MAKEFILE_FOLDER} && \
	    . ${MAKEFILE_FOLDER}/env/bin/activate && \
	    for i in {1..10} ; \
	    do \
	    	pypy3 hexspeak.py 14 abcdef ../words ; \
	    done" | \
	    awk '{print $$4; fflush();}' | \
	    tee ${MAKEFILE_FOLDER}/../../results/timings.hy_pypy.txt | \
	    ${MAKEFILE_FOLDER}/../../contrib/stats.py | \
	    grep Min

clean:
	rm -rf hy hylang __pycache__/ env hexspeak.py
