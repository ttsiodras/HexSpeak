TARGET=target/uberjar/thanassis-0.1.0-SNAPSHOT-standalone.jar

all:	${TARGET}

${TARGET}:	src/thanassis/core.clj
	./compile.sh
