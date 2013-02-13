declare i8* @gets(i8*)
declare i8* @strtok(i8*, i8*)
declare i8* @malloc(i64)

@prompt = constant [3 x i8] c"> \00"
@indent = constant [3 x i8] c"  \00"
@max_input = constant [256 x i8] zeroinitializer

define i32 @main() {
  ; print "> "
  %prompt = getelementptr [3 x i8]* @prompt, i64 0, i64 0
  call i32 @print(i8* %prompt)
  ; get string
  ; %stdin = getelementptr [256 x i8]* @max_input, i64 0, i64 0
  ; call i8* @gets(i8* %stdin)
  %empty_stack = call %stack* @new_stack()
  %s = call %stack* @read(%stack* %empty_stack)
  %ops = call %stack* @reverse(%stack* %s)
  %s_new = call %stack* @eval_stack(%stack* %ops)
;  call i32 @print_stack(%stack* %empty_stack)
  %s_rev = call %stack* @reverse(%stack* %s_new)
  %indent = getelementptr [3 x i8]* @indent, i64 0, i64 0
  call i32 @print(i8* %indent)
  call i32 @print_stack(%stack* %s_rev)
  call i32 @println()
;  call i32 @print_stack(%stack* @example_stack2)
  ; exit gracefully
  ret i32 0
}

@empty_str = constant [1 x i8] c"\00"

define i32 @println() {
  %ptr = getelementptr [1 x i8]* @empty_str, i64 0, i64 0
  %ret = call i32 @puts(i8* %ptr)
  ret i32 %ret
}

;;;;;;;;;;;;;;;;; old stuff ;;;;;;;;;;;;;;;;;;;;;;;;


declare i32 @puts(i8*)
declare i32 @getchar()
declare i32 @printf(i8*, ...)
declare i32 @strncmp(i8*, i8*, i32)
declare i32 @strcmp(i8*, i8*)

@printf_s = constant [3 x i8] c"%s\00"
@printf_c = constant [3 x i8] c"%c\00"
@printf_c2 = constant [3 x i8] c"%c\00"

@found_open = constant [9 x i8] c"Found: [\00"
@found_close = constant [9 x i8] c"Found: ]\00"
@found_name = constant [13 x i8] c"Found a name\00"
@found_error = constant [7 x i8] c"error!\00"

@max_word_length = constant i8 256

;;; keywords

@keyword_drop = constant [5 x i8] c"drop\00"
@keyword_dup = constant [4 x i8] c"dup\00"
@keyword_dip = constant [4 x i8] c"dip\00"
@keyword_do = constant [3 x i8] c"do\00"

;;; token tag enums

;@tok_tag_error = constant i4 0
@tok_tag_name = constant i4 1
@tok_tag_bracket_open = constant i4 2
@tok_tag_bracket_close = constant i4 3

;;; types

;%name = type [256 x i8]
;%tag = type i4
;%token = type {%tag, %name*}

%name = type [256 x i8]
%stack = type {i1, %elem, %stack*}
%elem = type {i1, %name*, %stack*}

define %elem @elem_from_name(%name* %n) {
  %e_with_tag = insertvalue %elem zeroinitializer, i1 0, 0
  %e = insertvalue %elem %e_with_tag, %name* %n, 1
  ret %elem %e
}

define %elem @elem_from_stack(%stack* %s) {
  %e_with_tag = insertvalue %elem zeroinitializer, i1 1, 0
  %e = insertvalue %elem %e_with_tag, %stack* %s, 2
  ret %elem %e
}

define %stack* @malloc_stack() {
  %one_Stack_long = getelementptr %stack* null, i64 1
  %sizeof_Stack = ptrtoint %stack* %one_Stack_long to i64
  %void_ptr = call i8* @malloc(i64 %sizeof_Stack)
  %ptr = bitcast i8* %void_ptr to %stack*
  ret %stack* %ptr
}

define %stack* @push_elem(%stack* %old_stack, %elem %e) {
  %s_with_elem = insertvalue %stack {i1 1, %elem undef, %stack* undef}, %elem %e, 1
  %new_stack = insertvalue %stack %s_with_elem, %stack* %old_stack, 2
;  %ptr = alloca %stack
  %ptr = call %stack* @malloc_stack()
  store %stack %new_stack, %stack* %ptr
  ret %stack* %ptr
}

@nil_stack = constant %stack {i1 0, %elem undef, %stack* undef}

define %stack* @new_stack2() {
  ret %stack* @nil_stack
}

define %stack* @new_stack() {
  ; %one_Stack_long = getelementptr %stack* null, i64 1
  ; %sizeof_Stack = ptrtoint %stack* %one_Stack_long to i64
  ; %void_ptr = call i8* @malloc(i64 %sizeof_Stack)
  ; %ptr = bitcast i8* %void_ptr to %stack*
;  %ptr = alloca %stack
  %ptr = call %stack* @malloc_stack()
  store %stack {i1 0, %elem undef, %stack* undef}, %stack* %ptr
  ret %stack* %ptr
;  ret %stack* undef
}

define %name* @malloc_name() {
  %sizeof_one = getelementptr %name* null, i64 1
  %size = ptrtoint %name* %sizeof_one to i64
  %void_ptr = call i8* @malloc(i64 %size)
  %ptr = bitcast i8* %void_ptr to %name*
  ret %name* %ptr
}

define %stack* @read(%stack* %old_stack) {
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
  %r = call %stack* @push_current_word(%stack* %old_stack, %name* %current_name, i64 %idx)
  ret %stack* %r
space:
  %new_stack = call %stack* @push_current_word(%stack* %old_stack, %name* %current_name, i64 %idx)
  %tail_ret = tail call %stack* @read(%stack* %new_stack)
  ret %stack* %tail_ret
bracket_open:
  ; push current word (if any)
  %stack3 = call %stack* @push_current_word(%stack* %old_stack, %name* %current_name, i64 %idx)
  ; create a new stack and push everything until ']' on that stack
  %empty_stack = call %stack* @new_stack()
  %read_until_rbracket = call %stack* @read(%stack* %empty_stack)
  ; add that stack as an element to our existing stack
  %elem_stack = call %elem @elem_from_stack(%stack* %read_until_rbracket)
  %stack_with_elem = call %stack* @push_elem(%stack* %stack3, %elem %elem_stack)
  %tail_ret3 = tail call %stack* @read(%stack* %stack_with_elem)
  ret %stack* %tail_ret3
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

define %stack* @push_current_word(%stack* %old_stack, %name* %word, i64 %idx) {
  %no_word_yet = icmp eq i64 %idx, 0
  br i1 %no_word_yet, label %just_return, label %push_and_return
just_return:
  ret %stack* %old_stack
push_and_return:
  %current_name_end = getelementptr %name* %word, i64 0, i64 %idx
  store i8 0, i8* %current_name_end ; null terminate the string
  %e = call %elem @elem_from_name(%name* %word)
  %new_stack = call %stack* @push_elem(%stack* %old_stack, %elem %e)
  ret %stack* %new_stack
}

%stack_ptr = type i32
; %stack = type {%stack_ptr, [1024 x %elem]}

 ; stack = nil (if i1 = 0) or %elem + ptr to next %elem




@name_drop = constant %name c"drop\00                                                                                                                                                                                                                                                          \00"
@name_dup = constant %name c"dup\00                                                                                                                                                                                                                                                           \00"
@name_dip = constant %name c"dip\00                                                                                                                                                                                                                                                           \00"
@name_do = constant %name c"do\00                                                                                                                                                                                                                                                            \00"

@example_stack = constant %stack {i1 1, %elem {i1 0, %name* @name_drop, %stack* @nil_stack}, %stack* @nil_stack}
@example_stack2 = constant %stack {i1 1, %elem {i1 0, %name* @name_dup, %stack* @nil_stack}, %stack* @example_stack}

@str_lbracket = constant [2 x i8] c"[\00"
@str_rbracket = constant [2 x i8] c"]\00"

%binary_stack_f = type %stack* (%stack*, %elem)

define %stack* @foldl(%binary_stack_f* %f, %stack* %init, %stack* %s) {
  %is_nil_ptr = getelementptr %stack* %s, i64 0, i32 0
  %is_nil = load i1* %is_nil_ptr
  br i1 %is_nil, label %not_nil, label %nil
nil:
  ret %stack* %init
not_nil:
  %e_ptr = getelementptr %stack* %s, i64 0, i32 1
  %e = load %elem* %e_ptr

  %rest_stack_ptr_ptr = getelementptr %stack* %s, i64 0, i32 2
  %rest = load %stack** %rest_stack_ptr_ptr

  %new_init = call %stack* %f(%stack* %init, %elem %e)
  %ret = tail call %stack* @foldl(%binary_stack_f* %f, %stack* %new_init, %stack* %rest)
  ret %stack* %ret
}

define %stack* @reverse(%stack* %s) {
  %empty = call %stack* @new_stack()
  %ret = tail call %stack* @foldl(%binary_stack_f* @push_elem, %stack* %empty, %stack* %s)
  ret %stack* %ret
}

define i32 @print_stack(%stack* %s) {
  %ret = tail call i32 @print_stack_with_space(%stack* %s, i1 0)
  ret i32 %ret
}

@just_space = constant [2 x i8] c" \00"

define i32 @print_stack_with_space(%stack* %s, i1 %space_delimited) {
  %is_nil_ptr = getelementptr %stack* %s, i64 0, i32 0
  %is_nil = load i1* %is_nil_ptr
  br i1 %is_nil, label %not_nil, label %nil
nil:
  ret i32 0
not_nil:
  br i1 %space_delimited, label %with_space, label %continue
with_space:
  %just_space = getelementptr [2 x i8]* @just_space, i64 0, i64 0
  call i32 @print(i8* %just_space)
  br label %continue
continue:
  %e_ptr = getelementptr %stack* %s, i64 0, i32 1
  %e = load %elem* %e_ptr
  %e_type = extractvalue %elem %e, 0
  %rest_stack_ptr_ptr = getelementptr %stack* %s, i64 0, i32 2
  %rest_stack_ptr = load %stack** %rest_stack_ptr_ptr
  br i1 %e_type, label %e_is_stack, label %e_is_name
e_is_name:
  %e_name = extractvalue %elem %e, 1
  %name_ptr = getelementptr %name* %e_name, i64 0, i64 0
  call i32 @print(i8* %name_ptr)
  %ret_name = tail call i32 @print_stack_with_space(%stack* %rest_stack_ptr, i1 1)
  ret i32 %ret_name
e_is_stack:
  %str_lbracket = getelementptr [2 x i8]* @str_lbracket, i64 0, i64 0
  call i32 @print(i8* %str_lbracket)
  %e_stack = extractvalue %elem %e, 2
  call i32 @print_stack_with_space(%stack* %e_stack, i1 0)
  %str_rbracket = getelementptr [2 x i8]* @str_rbracket, i64 0, i64 0
  %ret_stack = call i32 @print(i8* %str_rbracket)
  %ret_rest = tail call i32 @print_stack_with_space(%stack* %rest_stack_ptr, i1 1)
;  ret i32 %ret_stack
  ret i32 %ret_rest
}

define %stack* @eval_stack(%stack* %ops) {
  %init = call %stack* @new_stack()
  %new = tail call %stack* @foldl(%binary_stack_f* @eval_elem, %stack* %init, %stack* %ops)
  ret %stack* %new
}

define %stack* @eval_elem(%stack* %old, %elem %e) {
  %e_type = extractvalue %elem %e, 0
  br i1 %e_type, label %e_is_stack, label %e_is_name
e_is_name:
  %e_name = extractvalue %elem %e, 1
  %stack_new = call %stack* @eval(%stack* %old, %name* %e_name)
  ret %stack* %stack_new
e_is_stack:
  %e_stack = extractvalue %elem %e, 2
  %e_stack_rev = call %stack* @reverse(%stack* %e_stack)
  %e_rev = call %elem @elem_from_stack(%stack* %e_stack_rev)
  %stack_with_stack = call %stack* @push_elem(%stack* %old, %elem %e_rev)
  ret %stack* %stack_with_stack
}

define %stack* @eval(%stack* %s, %name* %w) {
  %word_ptr = getelementptr %name* %w, i64 0, i64 0
  %is_drop = call i1 @is_drop(i8* %word_ptr)
  br i1 %is_drop, label %drop, label %not_drop
not_drop:
  %is_dup = call i1 @is_dup(i8* %word_ptr)
  br i1 %is_dup, label %dup, label %not_dup
not_dup:
  %is_dip = call i1 @is_dip(i8* %word_ptr)
  br i1 %is_dip, label %dip, label %not_dip
not_dip:
  %is_do = call i1 @is_do(i8* %word_ptr)
  br i1 %is_do, label %do, label %not_keyword
not_keyword:
  ret %stack* undef
drop:
  %ret_drop = tail call %stack* @eval_drop(%stack* %s)
  ret %stack* %ret_drop
;  ret %stack* undef
dup:
  %ret_dup = tail call %stack* @eval_dup(%stack* %s)
  ret %stack* %ret_dup
dip:
  ret %stack* %s
do:
  ret %stack* %s
}

define %stack* @eval_drop(%stack* %s) {
  %is_nil_ptr = getelementptr %stack* %s, i64 0, i32 0
  %is_nil = load i1* %is_nil_ptr
  br i1 %is_nil, label %not_nil, label %nil
nil:
  ; handle underflow here
  ret %stack* %s
not_nil:
  %rest_stack_ptr_ptr = getelementptr %stack* %s, i64 0, i32 2
  %rest = load %stack** %rest_stack_ptr_ptr
  ret %stack* %rest
}

define %stack* @eval_dup(%stack* %s) {
  %is_nil_ptr = getelementptr %stack* %s, i64 0, i32 0
  %is_nil = load i1* %is_nil_ptr
  br i1 %is_nil, label %not_nil, label %nil
nil:
  ; handle underflow here
  ret %stack* %s
not_nil:
  %e_ptr = getelementptr %stack* %s, i64 0, i32 1
  %e = load %elem* %e_ptr
  %new_stack = tail call %stack* @push_elem(%stack* %s, %elem %e)
  ret %stack* %new_stack
}

define i1 @is_drop(i8* %n) {
  %keyword = getelementptr [5 x i8]* @keyword_drop, i64 0, i64 0
  %result = call i32 @strcmp(i8* %n, i8* %keyword)
  %ret = icmp eq i32 %result, 0
  ret i1 %ret
}

define i1 @is_dup(i8* %n) {
  %keyword = getelementptr [4 x i8]* @keyword_dup, i64 0, i64 0
  %result = call i32 @strcmp(i8* %n, i8* %keyword)
  %ret = icmp eq i32 %result, 0
  ret i1 %ret
}

define i1 @is_dip(i8* %n) {
  %keyword = getelementptr [4 x i8]* @keyword_dip, i64 0, i64 0
  %result = call i32 @strcmp(i8* %n, i8* %keyword)
  %ret = icmp eq i32 %result, 0
  ret i1 %ret
}

define i1 @is_do(i8* %n) {
  %keyword = getelementptr [3 x i8]* @keyword_do, i64 0, i64 0
  %result = call i32 @strcmp(i8* %n, i8* %keyword)
  %ret = icmp eq i32 %result, 0
  ret i1 %ret
}

; like puts, but without newline
define i32 @print(i8* %str) {
  %printf_str = getelementptr [3 x i8]* @printf_s, i64 0, i64 0
  %ret = call i32 (i8*, ...)* @printf(i8* %printf_str, i8* %str)
  ret i32 %ret
}

define i32 @repl2() {
  %str1 = getelementptr [3 x i8]* @printf_s, i64 0, i64 0
  %str2 = getelementptr [3 x i8]* @printf_c, i64 0, i64 0
  call i32 @strncmp(i8* %str1, i8* %str2, i32 256)
  ; %prompt = getelementptr [3 x i8]* @prompt, i64 0, i64 0
  ; call i32 @print(i8* %prompt)
  ; %tok = call %token @read_token()
  ; call void @print_token(%token %tok)
  ; %ret = tail call i32 @repl()
  ret i32 0
}
