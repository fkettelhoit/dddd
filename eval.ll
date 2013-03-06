declare i32 @strcmp(i8*, i8*)

;;; keywords

@keyword_drop = constant [5 x i8] c"drop\00"
@keyword_dup = constant [4 x i8] c"dup\00"
@keyword_dip = constant [4 x i8] c"dip\00"
@keyword_do = constant [3 x i8] c"do\00"

;;; types

%name = type [256 x i8]

%Stack = type %Stack_Cell**
%Stack_Cell = type opaque

%Elem = type {i1, %name*, %Stack}

declare i1 @is_nil(%Stack)
declare %Stack @empty()
declare %Elem @pop(%Stack)
declare void @push(%Stack, %Elem)
declare void @flip(%Stack)

declare %Elem @elem_from_name(%name*)
declare %Elem @elem_from_stack(%Stack)

define void @eval_stack(%Stack %stack, %Stack %ops) {
  %is_nil = call i1 @is_nil(%Stack %ops)
  br i1 %is_nil, label %nil, label %not_nil
nil:
  ret void
not_nil:
  %op = call %Elem @pop(%Stack %ops)
  call void @eval_elem(%Stack %stack, %Elem %op)
  tail call void @eval_stack(%Stack %stack, %Stack %ops)
  ret void
}

define void @eval_elem(%Stack %stack, %Elem %e) {
  %e_type = extractvalue %Elem %e, 0
  br i1 %e_type, label %e_is_stack, label %e_is_name
e_is_name:
  %e_name = extractvalue %Elem %e, 1
  tail call void @eval(%Stack %stack, %name* %e_name)
  ret void
e_is_stack:
  %e_stack = extractvalue %Elem %e, 2
  call void @flip(%Stack %e_stack)
  %e_flipped = call %Elem @elem_from_stack(%Stack %e_stack)
  tail call void @push(%Stack %stack, %Elem %e_flipped)
  ret void
}

define void @eval(%Stack %s, %name* %w) {
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
  ret void
drop:
  tail call void @eval_drop(%Stack %s)
  ret void
dup:
  tail call void @eval_dup(%Stack %s)
  ret void
dip:
  tail call void @eval_dip(%Stack %s)
  ret void
do:
  tail call void @eval_do(%Stack %s)
  ret void
}

define void @eval_drop(%Stack %stack) {
  %is_nil = call i1 @is_nil(%Stack %stack)
  br i1 %is_nil, label %nil, label %not_nil
nil:
  ; handle underflow here
  ret void
not_nil:
  call %Elem @pop(%Stack %stack)
  ret void
}

define %Stack @copy_stack(%Stack %stack) {
  %acc = call %Stack @empty()
  call void @copy_stack_(%Stack %acc, %Stack %stack)
  ret %Stack %acc
}

define void @copy_stack_(%Stack %acc, %Stack %stack) {
  %is_nil = call i1 @is_nil(%Stack %stack)
  br i1 %is_nil, label %nil, label %not_nil
nil:
  ret void
not_nil:
  %e = call %Elem @pop(%Stack %stack)
  %e_copy = call %Elem @copy_elem(%Elem %e)

  call void @copy_stack_(%Stack %acc, %Stack %stack)

  call void @push(%Stack %stack, %Elem %e)
  call void @push(%Stack %acc, %Elem %e_copy)
  ret void
}

define %Elem @copy_elem(%Elem %e) {
  %e_type = extractvalue %Elem %e, 0
  br i1 %e_type, label %e_is_stack, label %e_is_name
e_is_stack:
  %e_stack = extractvalue %Elem %e, 2
  %e_stack_copy = call %Stack @copy_stack(%Stack %e_stack)
  %e_copy = call %Elem @elem_from_stack(%Stack %e_stack_copy)
  ret %Elem %e_copy
e_is_name:
  ret %Elem %e
}

define void @eval_dup(%Stack %stack) {
  %is_nil = call i1 @is_nil(%Stack %stack)
  br i1 %is_nil, label %nil, label %not_nil
nil:
  ; handle underflow here
  ret void
not_nil:
  %e = call %Elem @pop(%Stack %stack)
  call void @push(%Stack %stack, %Elem %e)

  %e_dup = call %Elem @copy_elem(%Elem %e)
  call void @push(%Stack %stack, %Elem %e_dup)

  ret void
}

define void @eval_dip(%Stack %stack) {
  %is_nil = call i1 @is_nil(%Stack %stack)
  br i1 %is_nil, label %nil, label %not_nil
nil:
  ; handle underflow here
  ret void
not_nil:
  %e_quot = call %Elem @pop(%Stack %stack)
  %e_type = extractvalue %Elem %e_quot, 0
  br i1 %e_type, label %e_is_stack, label %e_is_name
e_is_stack:
;  %quot = extractvalue %Elem %e, 2
  %is_rest_nil = call i1 @is_nil(%Stack %stack)
  br i1 %is_nil, label %rest_nil, label %rest_not_nil
e_is_name:
  ; handle the case when the element is not a quotation
  ret void
rest_nil:
  ; handle underflow here
  ret void
rest_not_nil:
  %e = call %Elem @pop(%Stack %stack)
  ; call eval here
  call void @push(%Stack %stack, %Elem %e)
  call void @push(%Stack %stack, %Elem %e_quot)
  ret void
}

define void @eval_do(%Stack %stack) {
  %is_nil = call i1 @is_nil(%Stack %stack)
  br i1 %is_nil, label %nil, label %not_nil
nil:
  ; handle underflow here
  ret void
not_nil:
  %e_quot = call %Elem @pop(%Stack %stack)
  %e_type = extractvalue %Elem %e_quot, 0
  br i1 %e_type, label %e_is_stack, label %e_is_name
e_is_stack:
  %quot = extractvalue %Elem %e_quot, 2
  tail call void @eval_stack(%Stack %stack, %Stack %quot)
  ret void
e_is_name:
  ; handle the case when the element is not a quotation
  ret void
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
