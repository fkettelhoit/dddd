declare i32 @puts(i8*)
declare i32 @getchar()
declare i32 @printf(i8*, ...)

@printf_s = constant [3 x i8] c"%s\00"
@printf_c = constant [3 x i8] c"%c\00"
@global_str = constant [2 x i8] c">\00"
@say_something = constant [2 x i8] c"!\00"

@max_word_length = constant i8 256

;;; token enums

@tok_error = constant i4 0
@tok_name = constant i4 1

;;; types

%name = type [256 x i8]
%tag = type i4
%token = type {%tag, %name*}

define %token @read_token() {
loop_header:
  ; read globals from memory
  %tok_error = load i4* @tok_error
  %tok_name = load i4* @tok_name
  
  ; create current_name to store function names in
  %current_name = alloca %name
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
space:
  store i8 0, i8* %current_name_end ; null terminate the string
  call i32 @puts(i8* %current_name_start)
  %t = call %token @name_token(%tag %tok_name, %name* %current_name)
  ret %token %t
newline:
  br label %return
;  ret %token {i4 0, %name %current_name}
;  ret i32 0
bracket_open:
  %str = getelementptr [2 x i8]* @say_something, i64 0, i64 0
  %printf_str = getelementptr [3 x i8]* @printf_s, i64 0, i64 0
  call i32 (i8*, ...)* @printf(i8* %printf_str, i8* %str)
  br label %return
;  ret %token {i4 0, %name %current_name}
;  ret i32 0
bracket_close:
  br label %return
;  ret %token {i4 0, %name %current_name}
;  ret i32 0
otherwise:
  %char_as_i8 = trunc i32 %char to i8
  store i8 %char_as_i8, i8* %current_name_end ; append char to current_name
  br label %loop
return:
  %t2 = insertvalue %token {%tag 0, %name* undef}, %name* %current_name, 1
  ret %token %t2
}

define %token @name_token(%tag %t, %name* %n) {
  %t1 = insertvalue %token {%tag undef, %name* undef}, %tag %t, 0
  %t2 = insertvalue %token %t1, %name* %n, 1
  ret %token %t2
}


define i32 @repl() {
  %str = getelementptr [2 x i8]* @global_str, i64 0, i64 0
  %printf_str = getelementptr [3 x i8]* @printf_s, i64 0, i64 0
  call i32 (i8*, ...)* @printf(i8* %printf_str, i8* %str)
  ; call i32 @puts(i8* %str)
  ; %char = call i32 @getchar()
  call %token @read_token()
  %ret = tail call i32 @repl()
  ret i32 %ret
}
        
define i32 @main() {
  %foo = tail call i32 @repl()
  ret i32 %foo
; LoopHeader:
;   %cond = add i1 0, 1
;   %temp = getelementptr [13 x i8]* @global_str, i64 0, i64 0
;   br label %Loop
; Loop:
;   %loopvar = phi i32 [0, %LoopHeader], [%nextloopvar, %Loop]
;   %nextloopvar = add i32 %loopvar, 1
;   call i32 @puts(i8* %temp)
;   br label %Loop


;   br i1 %cond, label %true, label %false
; true:
;   call i32 @puts(i8* %temp)
;   ret i32 0
; false:
;   ret i32 0
}
