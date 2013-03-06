SOURCES := stack.ll eval.ll alpha.ll
OBJECTS := ${SOURCES:.ll=.bc}
EXECUTABLE := dddd.bc

all: $(OBJECTS)
	llvm-link $(OBJECTS) -o $(EXECUTABLE)

%.bc: %.ll
	llvm-as $<
