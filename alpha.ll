declare i32 @puts(i8*)
declare i32 @getchar()
declare i32 @printf(i8*, ...)

@printf_s = constant [3 x i8] c"%s\00"
@printf_c = constant [3 x i8] c"%c\00"

@prompt = constant [3 x i8] c"> \00"

@found_open = constant [9 x i8] c"Found: [\00"
@found_close = constant [9 x i8] c"Found: ]\00"
@found_name = constant [13 x i8] c"Found a name\00"
@found_error = constant [7 x i8] c"error!\00"

@max_word_length = constant i8 256

;;; token tag enums

;@tok_tag_error = constant i4 0
@tok_tag_name = constant i4 1
@tok_tag_bracket_open = constant i4 2
@tok_tag_bracket_close = constant i4 3

;;; types

%name = type [256 x i8]
%tag = type i4
%token = type {%tag, %name*}

define %token @read_token() {
loop_header:
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
newline:
  br label %space
space:
  store i8 0, i8* %current_name_end ; null terminate the string
  call i32 @puts(i8* %current_name_start)
  %t = call %token @name_token(%name* %current_name)
  ret %token %t
bracket_open:
  %tag_bracket_open = load %tag* @tok_tag_bracket_open
  %tok_bracket_open = call %token @tok_from_tag(%tag %tag_bracket_open)
  ret %token %tok_bracket_open
bracket_close:
  %tag_bracket_close = load %tag* @tok_tag_bracket_close
  %tok_bracket_close = call %token @tok_from_tag(%tag %tag_bracket_close)
  ret %token %tok_bracket_close
otherwise:
  %char_as_i8 = trunc i32 %char to i8
  store i8 %char_as_i8, i8* %current_name_end ; append char to current_name
  br label %loop
}

define %token @tok_from_tag(%tag %tok_tag) {
  %tok = insertvalue %token undef, %tag %tok_tag, 0
  ret %token %tok
}

define %token @name_token(%name* %n) {
  %tok_tag = load %tag* @tok_tag_name
  %tok_with_tag = insertvalue %token undef, %tag %tok_tag, 0
  %tok_with_name = insertvalue %token %tok_with_tag, %name* %n, 1
  ret %token %tok_with_name
}

define void @print_token(%token %tok) {
  %tag_name = load %tag* @tok_tag_name
  %tag_bracket_open = load %tag* @tok_tag_bracket_open
  %tag_bracket_close = load %tag* @tok_tag_bracket_close

  %tok_tag = extractvalue %token %tok, 0

  %is_name = icmp eq %tag %tok_tag, %tag_name
  br i1 %is_name, label %name, label %else_if1
else_if1:
  %is_bracket_open = icmp eq %tag %tok_tag, %tag_bracket_open
  br i1 %is_bracket_open, label %bracket_open, label %else_if2
else_if2:
  %is_bracket_close = icmp eq %tag %tok_tag, %tag_bracket_close
  br i1 %is_bracket_close, label %bracket_close, label %error

name:
  %found_name = getelementptr [13 x i8]* @found_name, i64 0, i64 0
  call i32 @puts(i8* %found_name)
  ret void
bracket_open:
  %found_open = getelementptr [9 x i8]* @found_open, i64 0, i64 0
  call i32 @puts(i8* %found_open)
  ret void
bracket_close:
  %found_close = getelementptr [9 x i8]* @found_close, i64 0, i64 0
  call i32 @puts(i8* %found_close)
  ret void
error:
  %found_error = getelementptr [7 x i8]* @found_error, i64 0, i64 0
  call i32 @puts(i8* %found_error)
  ret void
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
  call void @print_token(%token %tok)
  %ret = tail call i32 @repl()
  ret i32 %ret
}
        
define i32 @main() {
  %ret = tail call i32 @repl()
  ret i32 %ret
}