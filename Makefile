all: alpha.bc stack.bc eval.bc
	llvm-link alpha.bc stack.bc eval.bc -o dddd.bc

alpha.bc: alpha.ll
	llvm-as alpha.ll

stack.bc: stack.ll
	llvm-as stack.ll

eval.bc: eval.ll
	llvm-as eval.ll
