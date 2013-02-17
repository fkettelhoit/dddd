all: alpha.bc stack.bc
	llvm-link alpha.bc stack.bc -o dddd.bc

alpha.bc: alpha.ll
	llvm-as alpha.ll

stack.bc: stack.ll
	llvm-as stack.ll
