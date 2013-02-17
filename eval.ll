declare i32 @strcmp(i8*, i8*)

;;; keywords

@keyword_drop = constant [5 x i8] c"drop\00"
@keyword_dup = constant [4 x i8] c"dup\00"
@keyword_dip = constant [4 x i8] c"dip\00"
@keyword_do = constant [3 x i8] c"do\00"

;;; types

%name = type [256 x i8]

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

define %Stack* @eval_stack(%Stack* %init, %Stack* %ops) {
  %new = tail call %Stack* @foldl(%Binary_stack_f* @eval_elem, %Stack* %init, %Stack* %ops)
  ret %Stack* %new
}

define %Stack* @eval_elem(%Stack* %old, %Elem %e) {
  %e_type = extractvalue %Elem %e, 0
  br i1 %e_type, label %e_is_stack, label %e_is_name
e_is_name:
  %e_name = extractvalue %Elem %e, 1
  %stack_new = call %Stack* @eval(%Stack* %old, %name* %e_name)
  ret %Stack* %stack_new
e_is_stack:
  %e_stack = extractvalue %Elem %e, 2
  %e_stack_rev = call %Stack* @reverse_rec(%Stack* %e_stack)
  %e_rev = call %Elem @elem_from_stack(%Stack* %e_stack_rev)
  %stack_with_stack = call %Stack* @push(%Stack* %old, %Elem %e_rev)
  ; %stack_with_stack = call %Stack* @push(%Stack* %old, %Elem %e)
  ret %Stack* %stack_with_stack
}

define %Stack* @eval(%Stack* %s, %name* %w) {
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
  ret %Stack* undef
drop:
  %ret_drop = tail call %Stack* @eval_drop(%Stack* %s)
  ret %Stack* %ret_drop
dup:
  %ret_dup = tail call %Stack* @eval_dup(%Stack* %s)
  ret %Stack* %ret_dup
dip:
  %ret_dip = tail call %Stack* @eval_dip(%Stack* %s)
  ret %Stack* %ret_dip
do:
  %ret_do = tail call %Stack* @eval_do(%Stack* %s)
  ret %Stack* %ret_do
}

define %Stack* @eval_drop(%Stack* %s) {
  ; %is_nil_ptr = getelementptr %Stack* %s, i64 0, i32 0
  ; %is_nil = load i1* %is_nil_ptr
  %is_nil = call i1 @is_nil(%Stack* %s)
  br i1 %is_nil, label %not_nil, label %nil
nil:
  ; handle underflow here
  ret %Stack* %s
not_nil:
  ; %rest_stack_ptr_ptr = getelementptr %Stack* %s, i64 0, i32 2
  ; %rest = load %Stack** %rest_stack_ptr_ptr
  %rest = call %Stack* @rest(%Stack* %s)
  ret %Stack* %rest
}

define %Stack* @eval_dup(%Stack* %s) {
  ; %is_nil_ptr = getelementptr %Stack* %s, i64 0, i32 0
  ; %is_nil = load i1* %is_nil_ptr
  %is_nil = call i1 @is_nil(%Stack* %s)
  br i1 %is_nil, label %not_nil, label %nil
nil:
  ; handle underflow here
  ret %Stack* %s
not_nil:
  ; %e_ptr = getelementptr %Stack* %s, i64 0, i32 1
  ; %e = load %Elem* %e_ptr
  %e = call %Elem @first(%Stack* %s)
;  %e_copy = call %Elem @copy_elem(%Elem %e)
  %new_stack = tail call %Stack* @push(%Stack* %s, %Elem %e)
  ret %Stack* %new_stack
}

define %Stack* @eval_dip(%Stack* %s) {
  ; %is_nil_ptr = getelementptr %Stack* %s, i64 0, i32 0
  ; %is_nil = load i1* %is_nil_ptr
  %is_nil = call i1 @is_nil(%Stack* %s)
  br i1 %is_nil, label %not_nil, label %nil
not_nil:
  %rest = call %Stack* @rest(%Stack* %s)
  ; %rest_stack_ptr_ptr = getelementptr %Stack* %s, i64 0, i32 2
  ; %rest = load %Stack** %rest_stack_ptr_ptr
  ; %e_ptr = getelementptr %Stack* %s, i64 0, i32 1
  ; %e = load %Elem* %e_ptr
  %e = call %Elem @first(%Stack* %s)
  %e_type = extractvalue %Elem %e, 0
  br i1 %e_type, label %e_is_stack, label %e_is_name
e_is_stack:
  %quot = extractvalue %Elem %e, 2
  ; %is_rest_nil_ptr = getelementptr %Stack* %rest, i64 0, i32 0
  ; %is_rest_nil = load i1* %is_rest_nil_ptr
  %is_rest_nil = call i1 @is_nil(%Stack* %rest)
  br i1 %is_rest_nil, label %rest_not_nil, label %rest_nil
rest_not_nil:
  %remaining = call %Stack* @rest(%Stack* %rest)
;  %remaining_stack_ptr_ptr = getelementptr %Stack* %rest, i64 0, i32 2
;  %remaining = load %Stack** %remaining_stack_ptr_ptr
  ; %e_dipped_ptr = getelementptr %Stack* %rest, i64 0, i32 1
  ; %e_dipped = load %Elem* %e_dipped_ptr
  %e_dipped = call %Elem @first(%Stack* %rest)

  %eval_quot = call %Stack* @eval_stack(%Stack* %remaining, %Stack* %quot)
  %new_stack = tail call %Stack* @push(%Stack* %eval_quot, %Elem %e_dipped)
  ret %Stack* %new_stack
nil:
  ; handle underflow here
  ret %Stack* undef
e_is_name:
  ; element should be a stack!
  ret %Stack* undef
rest_nil:
  ; handle underflow
  ret %Stack* undef
}

define %Stack* @eval_do(%Stack* %s) {
  ; %is_nil_ptr = getelementptr %Stack* %s, i64 0, i32 0
  ; %is_nil = load i1* %is_nil_ptr
  %is_nil = call i1 @is_nil(%Stack* %s)
  br i1 %is_nil, label %not_nil, label %nil
not_nil:
  %rest = call %Stack* @rest(%Stack* %s)
  %e = call %Elem @first(%Stack* %s)

;  %rest_stack_ptr_ptr = getelementptr %Stack* %s, i64 0, i32 2
;  call void @free_stack(%Stack* %s)
;  %rest = load %Stack** %rest_stack_ptr_ptr
;  %e_ptr = getelementptr %Stack* %s, i64 0, i32 1
;  %e = load %Elem* %e_ptr
  %e_type = extractvalue %Elem %e, 0
  br i1 %e_type, label %e_is_stack, label %e_is_name
e_is_stack:
  %quot = extractvalue %Elem %e, 2
  %new_stack = tail call %Stack* @eval_stack(%Stack* %rest, %Stack* %quot)
;  call void @free_stack_rec(%Stack* %quot)
  ret %Stack* %new_stack
nil:
  ; handle underflow here
  ret %Stack* undef
e_is_name:
  ; element should be a stack!
  ret %Stack* undef
}

; endless loop for dip:
; [dup dup dip] [] [dup dup dip] dip

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
