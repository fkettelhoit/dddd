declare i8* @malloc(i64)
declare void @free(i8*)
declare i8* @strncpy(i8*, i8*, i32)

;;; types

%name = type [256 x i8]
;%Stack = type {%Elem, %Stack*}

%Elem = type {i1, %name*, %Stack*}
%Binary_stack_f = type %Stack* (%Stack*, %Elem)

;;; Stack type ;;;

%Stack = type opaque

declare i1 @is_nil(%Stack*)
declare %Elem @first(%Stack*)
declare %Stack* @rest(%Stack*)
declare %Stack* @empty()
declare %Stack* @push(%Stack*, %Elem)

declare %Stack* @reverse_rec(%Stack*)
declare %Elem @elem_from_name(%name*)
declare %Elem @elem_from_stack(%Stack*)
declare %Stack* @foldl(%Binary_stack_f*, %Stack*, %Stack*)

;;; use eval.ll ;;;

declare %Stack* @eval_stack(%Stack*, %Stack*)

;;;

@prompt = constant [3 x i8] c"> \00"
@indent = constant [3 x i8] c"  \00"

define i32 @main() {
start:
  %init = call %Stack* @empty()
  br label %loop
loop:
  %stack_old = phi %Stack* [%init, %start], [%stack_new, %loop]
;  %stack_old = call %Stack* @reverse_rec(%Stack* %stack_old2)
  ; read
  %prompt = getelementptr [3 x i8]* @prompt, i64 0, i64 0
  call i32 @print(i8* %prompt)
  %ops_rev = call %Stack* @read()
  %ops = call %Stack* @reverse_rec(%Stack* %ops_rev)
  ; eval
  %stack_new = call %Stack* @eval_stack(%Stack* %stack_old, %Stack* %ops)
  ; print
  %stack_new_rev = call %Stack* @reverse_rec(%Stack* %stack_new)
  %indent = getelementptr [3 x i8]* @indent, i64 0, i64 0
  call i32 @print(i8* %indent)
  call i32 @print_stack(%Stack* %stack_new_rev)
  call i32 @println()
  ; loop
  br label %loop
}

@empty_str = constant [1 x i8] c"\00"

define i32 @println() {
  %ptr = getelementptr [1 x i8]* @empty_str, i64 0, i64 0
  %ret = call i32 @puts(i8* %ptr)
  ret i32 %ret
}

declare i32 @puts(i8*)
declare i32 @getchar()
declare i32 @printf(i8*, ...)
declare i32 @strcmp(i8*, i8*)

@printf_s = constant [3 x i8] c"%s\00"
@printf_c = constant [3 x i8] c"%c\00"
@printf_c2 = constant [3 x i8] c"%c\00"

@max_word_length = constant i8 256


define %name* @copy_name(%name* %n) {
  %n_copy = call %name* @malloc_name()
  %n_ptr = getelementptr %name* %n, i64 0, i64 0
  %n_copy_ptr = getelementptr %name* %n_copy, i64 0, i64 0
  call i8* @strncpy(i8* %n_copy_ptr, i8* %n_ptr, i32 256)
  ret %name* %n_copy
}

define %name* @malloc_name() {
  %sizeof_one = getelementptr %name* null, i64 1
  %size = ptrtoint %name* %sizeof_one to i64
  %void_ptr = call i8* @malloc(i64 %size)
  %ptr = bitcast i8* %void_ptr to %name*
  ret %name* %ptr
}

define void @free_name(%name* %n) {
  %ptr = bitcast %name* %n to i8*
  call void @free(i8* %ptr)
  ret void
}

define %Stack* @read() {
  %empty = call %Stack* @empty()
  %ret = tail call %Stack* @read_(%Stack* %empty)
  ret %Stack* %ret
}

define %Stack* @read_(%Stack* %old_stack) {
loop_header:
;  %current_name = alloca %name
  %current_name = call %name* @malloc_name()
  %current_name_start = getelementptr %name* %current_name, i64 0, i64 0
  br label %loop
loop:
  %idx = phi i64 [0, %loop_header], [%next_idx, %otherwise]
  %next_idx = add i64 %idx, 1
  %char = call i32 @getchar()

  %current_name_end = getelementptr %name* %current_name, i64 0, i64 %idx

  switch i32 %char, label %otherwise
          [ i32 10, label %newline         ; 10 = '\n'
            i32 32, label %space           ; 32 = ' '
            i32 91, label %bracket_open    ; 91 = '['
            i32 93, label %bracket_close ] ; 93 = ']'
newline:
  %r = call %Stack* @push_current_word(%Stack* %old_stack, %name* %current_name, i64 %idx)
  ret %Stack* %r
space:
  %new_stack = call %Stack* @push_current_word(%Stack* %old_stack, %name* %current_name, i64 %idx)
  %tail_ret = tail call %Stack* @read_(%Stack* %new_stack)
  ret %Stack* %tail_ret
bracket_open:
  ; push current word (if any)
  %stack3 = call %Stack* @push_current_word(%Stack* %old_stack, %name* %current_name, i64 %idx)
  ; create a new stack and push everything until ']' on that stack
;  %empty_stack = call %Stack* @empty()
  %read_until_rbracket = call %Stack* @read()
  ; add that stack as an element to our existing stack
  %elem_stack = call %Elem @elem_from_stack(%Stack* %read_until_rbracket)
  %stack_with_elem = call %Stack* @push(%Stack* %stack3, %Elem %elem_stack)
  %tail_ret3 = tail call %Stack* @read_(%Stack* %stack_with_elem)
  ret %Stack* %tail_ret3
bracket_close:
  br label %newline
; bracket_open:
;   %tag_bracket_open = load %tag* @tok_tag_bracket_open
;   %tok_bracket_open = call %token @tok_from_tag(%tag %tag_bracket_open)
;   ret %token %tok_bracket_open
; bracket_close:
;   %tag_bracket_close = load %tag* @tok_tag_bracket_close
;   %tok_bracket_close = call %token @tok_from_tag(%tag %tag_bracket_close)
;   ret %token %tok_bracket_close
otherwise:
  %char_as_i8 = trunc i32 %char to i8
  store i8 %char_as_i8, i8* %current_name_end ; append char to current_name
  br label %loop
}

define %Stack* @push_current_word(%Stack* %old_stack, %name* %word, i64 %idx) {
  %no_word_yet = icmp eq i64 %idx, 0
  br i1 %no_word_yet, label %just_return, label %push_and_return
just_return:
  ret %Stack* %old_stack
push_and_return:
  %current_name_end = getelementptr %name* %word, i64 0, i64 %idx
  store i8 0, i8* %current_name_end ; null terminate the string
  %e = call %Elem @elem_from_name(%name* %word)
  %new_stack = call %Stack* @push(%Stack* %old_stack, %Elem %e)
  ret %Stack* %new_stack
}

@name_drop = constant %name c"drop\00                                                                                                                                                                                                                                                          \00"
@name_dup = constant %name c"dup\00                                                                                                                                                                                                                                                           \00"
@name_dip = constant %name c"dip\00                                                                                                                                                                                                                                                           \00"
@name_do = constant %name c"do\00                                                                                                                                                                                                                                                            \00"

; @example_stack = constant %Stack {i1 1, %Elem {i1 0, %name* @name_drop, %Stack* @nil_stack}, %Stack* @nil_stack}
; @example_stack2 = constant %Stack {i1 1, %Elem {i1 0, %name* @name_dup, %Stack* @nil_stack}, %Stack* @example_stack}

@str_lbracket = constant [2 x i8] c"[\00"
@str_rbracket = constant [2 x i8] c"]\00"




define i32 @print_stack(%Stack* %s) {
  %ret = tail call i32 @print_stack_with_space(%Stack* %s, i1 0)
  ret i32 %ret
}

@just_space = constant [2 x i8] c" \00"

define i32 @print_stack_with_space(%Stack* %s, i1 %space_delimited) {
  ; %is_nil_ptr = getelementptr %Stack* %s, i64 0, i32 0
  ; %is_nil = load i1* %is_nil_ptr
  %is_nil = call i1 @is_nil(%Stack* %s)
  br i1 %is_nil, label %nil, label %not_nil
nil:
  ret i32 0
not_nil:
  br i1 %space_delimited, label %with_space, label %continue
with_space:
  %just_space = getelementptr [2 x i8]* @just_space, i64 0, i64 0
  call i32 @print(i8* %just_space)
  br label %continue
continue:
  ; %e_ptr = getelementptr %Stack* %s, i64 0, i32 1
  ; %e = load %Elem* %e_ptr
  %e = call %Elem @first(%Stack* %s)
  %e_type = extractvalue %Elem %e, 0
  ; %rest_stack_ptr_ptr = getelementptr %Stack* %s, i64 0, i32 2
  ; %rest_stack_ptr = load %Stack** %rest_stack_ptr_ptr
  %rest_stack_ptr = call %Stack* @rest(%Stack* %s)
  br i1 %e_type, label %e_is_stack, label %e_is_name
e_is_name:
  %e_name = extractvalue %Elem %e, 1
  %name_ptr = getelementptr %name* %e_name, i64 0, i64 0
  call i32 @print(i8* %name_ptr)
  %ret_name = tail call i32 @print_stack_with_space(%Stack* %rest_stack_ptr, i1 1)
  ret i32 %ret_name
e_is_stack:
  %str_lbracket = getelementptr [2 x i8]* @str_lbracket, i64 0, i64 0
  call i32 @print(i8* %str_lbracket)
  %e_stack = extractvalue %Elem %e, 2
  call i32 @print_stack_with_space(%Stack* %e_stack, i1 0)
  %str_rbracket = getelementptr [2 x i8]* @str_rbracket, i64 0, i64 0
  %ret_stack = call i32 @print(i8* %str_rbracket)
  %ret_rest = tail call i32 @print_stack_with_space(%Stack* %rest_stack_ptr, i1 1)
;  ret i32 %ret_stack
  ret i32 %ret_rest
}

; like puts, but without newline
define i32 @print(i8* %str) {
  %printf_str = getelementptr [3 x i8]* @printf_s, i64 0, i64 0
  %ret = call i32 (i8*, ...)* @printf(i8* %printf_str, i8* %str)
  ret i32 %ret
}