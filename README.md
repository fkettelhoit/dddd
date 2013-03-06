# DDDD

DDDD is an interpreter for a very simple stack-based language, written completely in LLVM assembly. At the moment the whole interpreter is still a work in progress, but basic stack manipulation is possible, even though some operations exhibit some strange behaviour (read: they don't really work...).

## The language

Basic concatenative stuff really. You can push stacks of operations onto the stack and you can execute operations on the stack. That's all. Everything inside \[ and \] is a stack. Stacks are pushed onto the stack unevaluated.

    [foo bar] [foobar]
    => [foo bar] [foobar]

The only operations that are supported right now are `dup drop do dip` (hence "dddd"). They work as follows:

* dup: duplicate the top element on the stack
* drop: drop the top element from the stack
* do: execute the top element of the stack
* dip: temporarily remove the top element from the stack, then act like do, then put the top element back

Here they are in action:

    [foo] [foo bar] dup
    => [foo] [foo bar] [foo bar]
    [foo] [foo bar] drop
    => [foo]
    [foo] [dup dup] do
    => [foo] [foo] [foo]
    [foo] [dup dup] [drop] dip
    => [foo] [foo] [foo]

Ah, one more thing: Right now there is no `swap`. To be honest, I have no idea why. I should just add it, I guess. But the name doesn't start with a "d" and so adding it would ruin the beautiful naming scheme of the language! Tough problem...

## But... Why?! I mean, in LLVM assembly? Really?!

Yes. Actually coding in LLVM assembly is a lot of fun once you get the hang of it (and it teaches you a lot about the LLVM IR obviously). It's not as comfortable as writing C, but the level of abstraction is very similar.