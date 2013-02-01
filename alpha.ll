declare i32 @puts(i8*)
declare i32 @getchar()
declare i32 @printf(i8*, ...)

@printf_s = constant [3 x i8] c"%s\00"
@printf_c = constant [3 x i8] c"%c\00"


@prompt = constant [3 x i8] c"> \00"

@max_word_length = constant i8 256

;;; token tag enums

@tok_tag_error = constant i4 0
@tok_tag_name = constant i4 1

;;; types

%name = type [256 x i8]
%tag = type i4
%token = type {%tag, %name*}

define %token @read_token() {
loop_header:
  ; read globals from memory
  %tok_error = load i4* @tok_tag_error
  %tok_name = load i4* @tok_tag_name
  
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
;  %t2 = insertvalue %token {%tag %tok_error, %name* undef}, %name* %current_name, 1
  %t2 = call %token @tok_error()
  ret %token %t2
}

define %token @tok_error() {
  %tok_tag_error = load i4* @tok_tag_error
  %t = insertvalue %token undef, %tag %tok_tag_error, 0
  ret %token %t
}

define %token @name_token(%tag %t, %name* %n) {
  %t1 = insertvalue %token {%tag undef, %name* undef}, %tag %t, 0
  %t2 = insertvalue %token %t1, %name* %n, 1
  ret %token %t2
}

; like puts, but without newline
define i32 @print(i8* %str) {
  %printf_str = getelementptr [3 x i8]* @printf_s, i64 0, i64 0
  %ret = call i32 (i8*, ...)* @printf(i8* %printf_str, i8* %str)
  ret i32 %ret
}

define i32 @repl() {
  %prompt = getelementptr [3 x i8]* @prompt, i64 0, i64 0
  call i32 @print(i8* %prompt)
  %tok = call %token @read_token()
  %ret = tail call i32 @repl()
  ret i32 %ret
}
        
define i32 @main() {
  %ret = tail call i32 @repl()
  ret i32 %ret
}
