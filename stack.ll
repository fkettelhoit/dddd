declare i8* @malloc(i64)
declare void @free(i8*)

%name = type [256 x i8]
%Stack = type {%Elem, %Stack*}
%Elem = type {i1, %name*, %Stack*}
%Binary_stack_f = type %Stack* (%Stack*, %Elem)

declare %name* @copy_name(%name*)

define i1 @is_nil(%Stack* %s) {
  %is_not_nil = icmp eq %Stack* %s, null
  %is_nil = xor i1 %is_not_nil, 1
  ret i1 %is_nil
  ; %is_not_nil_ptr = getelementptr %Stack* %s, i64 0, i32 0
  ; %is_not_nil = load i1* %is_not_nil_ptr
  ; %is_nil = xor i1 %is_not_nil, 1
  ; ret i1 %is_nil
}

define %Elem @first(%Stack* %stack) {
  %first_ptr = getelementptr %Stack* %stack, i64 0, i32 0
  %first = load %Elem* %first_ptr
  ret %Elem %first
}

define %Stack* @rest(%Stack* %stack) {
  %rest_ptr_ptr = getelementptr %Stack* %stack, i64 0, i32 1
  %rest_ptr = load %Stack** %rest_ptr_ptr
  ret %Stack* %rest_ptr
}

define %Stack* @malloc_stack() {
  %one_Stack_long = getelementptr %Stack* null, i64 1
  %sizeof_Stack = ptrtoint %Stack* %one_Stack_long to i64
  %void_ptr = call i8* @malloc(i64 %sizeof_Stack)
  %ptr = bitcast i8* %void_ptr to %Stack*
  ret %Stack* %ptr
}

define void @free_stack(%Stack* %s) {
  ; %e_ptr = getelementptr %Stack* %s, i64 0, i32 0
  ; %e = load %Elem* %e_ptr
  ; call void @free_elem(%Elem %e)
  ; %ptr = bitcast %Stack* %s to i8*
  ; call void @free(i8* %ptr)
  ret void
}

define void @free_stack_rec(%Stack* %s) {
; ;  %is_nil_ptr = getelementptr %Stack* %s, i64 0, i32 0
; ;  %is_nil = load i1* %is_nil_ptr
;   %is_nil = call i1 @is_nil(%Stack* %s)
;   br i1 %is_nil, label %not_nil, label %nil
; nil:
;   ret void
; not_nil:
;   ; %rest_ptr_ptr = getelementptr %Stack* %s, i64 0, i32 2
;   ; %rest_ptr = load %Stack** %rest_ptr_ptr
;   %rest_ptr = call %Stack* @rest(%Stack* %s)
;   call void @free_stack_rec(%Stack* %rest_ptr)
;   call void @free_stack(%Stack* %s)
  ret void
}

define void @free_elem(%Elem %e) {
;   %e_type = extractvalue %Elem %e, 0
;   br i1 %e_type, label %e_is_stack, label %e_is_name
; e_is_stack:
;   %e_stack = extractvalue %Elem %e, 2
;   call void @free_stack_rec(%Stack* %e_stack)
;   ret void
; e_is_name:
;   %e_name = extractvalue %Elem %e, 1
;   call void @free_name(%name* %e_name)
  ret void
}

define %Elem @copy_elem(%Elem %e) {
  %e_type = extractvalue %Elem %e, 0
  br i1 %e_type, label %e_is_stack, label %e_is_name
e_is_stack:
  %e_stack = extractvalue %Elem %e, 2
  %stack_copy = call %Stack* @copy_stack(%Stack* %e_stack)
  %e_new_stack = call %Elem @elem_from_stack(%Stack* %stack_copy)
  ret %Elem %e_new_stack
e_is_name:
  %e_name = extractvalue %Elem %e, 1
  %name_copy = call %name* @copy_name(%name* %e_name)
  %e_new_name = call %Elem @elem_from_name(%name* %name_copy)
  ret %Elem %e_new_name
}

define %Stack* @push_copy_elem(%Stack* %s, %Elem %e) {
  %e_copy = call %Elem @copy_elem(%Elem %e)
  %ret = tail call %Stack* @push_elem(%Stack* %s, %Elem %e_copy)
  ret %Stack* %ret
}

define %Stack* @push_elem_rev(%Stack* %s, %Elem %e) {
  %e_type = extractvalue %Elem %e, 0
  br i1 %e_type, label %e_is_stack, label %e_is_name
e_is_stack:
  %e_stack = extractvalue %Elem %e, 2
  %stack_copy = call %Stack* @reverse_rec(%Stack* %e_stack)
  %e_new_stack = call %Elem @elem_from_stack(%Stack* %stack_copy)
  br label %return
;  ret %Elem %e_new_stack
e_is_name:
  %e_name = extractvalue %Elem %e, 1
  %name_copy = call %name* @copy_name(%name* %e_name)
  %e_new_name = call %Elem @elem_from_name(%name* %name_copy)
  br label %return
;  ret %Elem %e_new_name
return:
  %e_new = phi %Elem [%e_new_stack, %e_is_stack], [%e_new_name, %e_is_name]
  %new_stack = call %Stack* @push_elem(%Stack* %s, %Elem %e_new)
  ret %Stack* %new_stack
}

define %Stack* @push_elem(%Stack* %old_stack, %Elem %e) {
  %s_with_elem = insertvalue %Stack {%Elem undef, %Stack* undef}, %Elem %e, 0
  %new_stack = insertvalue %Stack %s_with_elem, %Stack* %old_stack, 1
  %ptr = call %Stack* @malloc_stack()
  store %Stack %new_stack, %Stack* %ptr
  ret %Stack* %ptr
}

define %Stack* @reverse_copy(%Stack* %s) {
  %empty = call %Stack* @new_stack()
  %s_rev = call %Stack* @foldl(%Binary_stack_f* @push_copy_elem, %Stack* %empty, %Stack* %s)
  ret %Stack* %s_rev
}

define %Stack* @reverse(%Stack* %s) {
  %empty = call %Stack* @new_stack()
  %ret = tail call %Stack* @foldl(%Binary_stack_f* @push_elem, %Stack* %empty, %Stack* %s)
  ret %Stack* %ret
}

define %Stack* @reverse_rec(%Stack* %s) {
  %empty = call %Stack* @new_stack()
  %ret = tail call %Stack* @foldl(%Binary_stack_f* @push_elem_rev, %Stack* %empty, %Stack* %s)
  ret %Stack* %ret
}

define %Stack* @copy_stack(%Stack* %s) {
  %s_rev = call %Stack* @reverse_copy(%Stack* %s)
  %s_rev_rev = call %Stack* @reverse_copy(%Stack* %s_rev)
;  call void @free_stack_rec(%Stack* %s_rev)
  ret %Stack* %s_rev_rev
}


define %Elem @elem_from_name(%name* %n) {
  %e_with_tag = insertvalue %Elem zeroinitializer, i1 0, 0
  %e = insertvalue %Elem %e_with_tag, %name* %n, 1
  ret %Elem %e
}

define %Elem @elem_from_stack(%Stack* %s) {
  %e_with_tag = insertvalue %Elem zeroinitializer, i1 1, 0
  %e = insertvalue %Elem %e_with_tag, %Stack* %s, 2
  ret %Elem %e
}

define %Stack* @foldl(%Binary_stack_f* %f, %Stack* %init, %Stack* %s) {
;  %is_nil_ptr = getelementptr %Stack* %s, i64 0, i32 0
;  %is_nil = load i1* %is_nil_ptr
  %is_nil = call i1 @is_nil(%Stack* %s)
  br i1 %is_nil, label %not_nil, label %nil
nil:
  ret %Stack* %init
not_nil:
  ; %e_ptr = getelementptr %Stack* %s, i64 0, i32 1
  ; %e = load %Elem* %e_ptr
  %e = call %Elem @first(%Stack* %s)

  ; %rest_stack_ptr_ptr = getelementptr %Stack* %s, i64 0, i32 2
  ; %rest = load %Stack** %rest_stack_ptr_ptr
  %rest = call %Stack* @rest(%Stack* %s)

  %new_init = call %Stack* %f(%Stack* %init, %Elem %e)
  %ret = tail call %Stack* @foldl(%Binary_stack_f* %f, %Stack* %new_init, %Stack* %rest)
  ret %Stack* %ret
}


define %Stack* @new_stack() {
  ; %ptr = call %Stack* @malloc_stack()
  ; store %Stack {i1 0, %Elem undef, %Stack* undef}, %Stack* %ptr
  ret %Stack* null
}
