declare i8* @malloc(i64)
declare void @free(i8*)


%name = type [256 x i8]

%Stack_Cell = type {%Elem, %Stack_Cell*}
%Stack = type %Stack_Cell**

%Elem = type {i1, %name*, %Stack}
%Binary_stack_f = type %Stack_Cell* (%Stack_Cell*, %Elem)

declare %name* @copy_name(%name*)

define i1 @is_nil(%Stack %ptr) {
  %stack = load %Stack %ptr
  %is_nil = icmp eq %Stack_Cell* %stack, null
  ret i1 %is_nil
}

define %Stack @empty() {
  ; malloc a new stack pointer
  %one_Stack_Ptr_long = getelementptr %Stack null, i64 1
  %sizeof_Stack_Ptr = ptrtoint %Stack %one_Stack_Ptr_long to i64
  %void_ptr = call i8* @malloc(i64 %sizeof_Stack_Ptr)
  %ptr = bitcast i8* %void_ptr to %Stack

  ; make the stack pointer point to null
  %ptr_ptr = getelementptr %Stack %ptr, i64 0
  store %Stack_Cell* null, %Stack %ptr_ptr

  ret %Stack %ptr  
}

define void @push(%Stack %ptr, %Elem %e) {
  ; look up the stack pointer
  %rest = load %Stack %ptr

  ; add the old stack as the rest of the new stack
  %stack_tmp = insertvalue %Stack_Cell {%Elem undef, %Stack_Cell* undef}, %Elem %e, 0
  %stack = insertvalue %Stack_Cell %stack_tmp, %Stack_Cell* %rest, 1

  ; store the new stack on the heap
  %stack_new = call %Stack_Cell* @malloc_stack()
  store %Stack_Cell %stack, %Stack_Cell* %stack_new

  ; change the stack pointer to the rest of the stack
  %ptr_ptr = getelementptr %Stack %ptr, i64 0
  store %Stack_Cell* %stack_new, %Stack %ptr_ptr

  ret void
}

define %Elem @pop(%Stack %ptr) {
  ; look up the stack pointer
  %stack = load %Stack %ptr

  ; load the element that needs to be popped
  %first_ptr = getelementptr %Stack_Cell* %stack, i64 0, i32 0
  %first = load %Elem* %first_ptr

  ; load a pointer to the rest of the stack
  %next_ptr_ptr = getelementptr %Stack_Cell* %stack, i64 0, i32 1
  %next_ptr = load %Stack_Cell** %next_ptr_ptr

  ; free the top of the stack
  %old_stack = bitcast %Stack_Cell* %stack to i8*
  call void @free(i8* %old_stack)

  ; change the stack pointer to the rest of the stack
  %ptr_ptr = getelementptr %Stack %ptr, i64 0
  store %Stack_Cell* %next_ptr, %Stack %ptr_ptr

  ; return the popped element
  ret %Elem %first
}

define %Stack_Cell* @malloc_stack() {
  %one_Stack_long = getelementptr %Stack_Cell* null, i64 1
  %sizeof_Stack = ptrtoint %Stack_Cell* %one_Stack_long to i64
  %void_ptr = call i8* @malloc(i64 %sizeof_Stack)
  %ptr = bitcast i8* %void_ptr to %Stack_Cell*
  ret %Stack_Cell* %ptr
}

define %Elem @elem_from_name(%name* %n) {
  %e_with_tag = insertvalue %Elem zeroinitializer, i1 0, 0
  %e = insertvalue %Elem %e_with_tag, %name* %n, 1
  ret %Elem %e
}

define %Elem @elem_from_stack(%Stack %s) {
  %e_with_tag = insertvalue %Elem zeroinitializer, i1 1, 0
  %e = insertvalue %Elem %e_with_tag, %Stack %s, 2
  ret %Elem %e
}

define void @flip(%Stack %stack) {
  ; create a new flipped stack
  %flipped = call %Stack @empty()
  call void @flip_(%Stack %stack, %Stack %flipped)

  ; get the first cell of the flipped stack
  %flipped_ptr = load %Stack %flipped

  ; let the stack pointer of the stack point to the flipped cell
  %ptr_ptr = getelementptr %Stack %stack, i64 0
  store %Stack_Cell* %flipped_ptr, %Stack %ptr_ptr

  ; still need to free the stack pointer of flipped
  ; todo

  ret void
}

define void @flip_(%Stack %stack, %Stack %flipped) {
  %is_nil = call i1 @is_nil(%Stack %stack)
  br i1 %is_nil, label %nil, label %not_nil
nil:
  ret void
not_nil:
  %e = call %Elem @pop(%Stack %stack)
  %e_type = extractvalue %Elem %e, 0
  br i1 %e_type, label %e_is_stack, label %continue
e_is_stack:
  %e_stack = extractvalue %Elem %e, 2
  call void @flip(%Stack %e_stack)
  %e_flipped = call %Elem @elem_from_stack(%Stack %e_stack)
  br label %continue
continue:
  %e_new = phi %Elem [%e, %not_nil], [%e_flipped, %e_is_stack]
  call void @push(%Stack %flipped, %Elem %e_new)

  tail call void @flip_(%Stack %stack, %Stack %flipped)
  ret void
}