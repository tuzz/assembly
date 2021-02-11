.global _main
.align 2

; TODO: write explanation
; TODO: update ./bin/generate

;   - x0 to xn: a combined bitset containing permutations we've visited
;   - x30: the return address automatically set by 'bl' instructions
;   - x29: a replacement stack pointer, so we can use it in a 'csel' instruction
;   - x28: the base memory address of the 'best_depths' array (16-bit integers)
;   - x27: the maximum allowed address into this array for the current subproblem
;   - x26: the current offset based on how many wasted characters there have been
;   - x25: four 16-bit integers containing the best depths for the current offset
;   - x24: one of the four 16-bit integers, extended to a full register
;   - x23: the best recursion depth we could hope to reach for the current string
;   - x22: the best recursion depth we've seen so far across all subproblems

_main:
  mov x29, sp               ; use x29 as a replacement stack pointer
  sub sp, sp, #(2 + 30)     ; move the stack pointer down so we can access its memory

  mov x28, sp               ; point x28 to some memory beneath our replacement stack
  bl init_best_depths       ; initialize the 'best_depths' array at that address

  mov x22, x29              ; the best depth we've seen so far is the current depth
  mov x27, x28              ; set max offset to the start of the best_depths array

  mov x0, #0                ; we haven't visited any nodes yet
                            ; (clear the other registers here, too)

  next_subproblem:
  mov x26, x27              ; reset the current offset to the maximum offset
  bl visit_12               ; exhaustively search, starting from permutation 12

  sub x24, x22, x29         ; calculate the best (relative) recursion depth we reached
  str x24, [x27, 6]         ; store the best depth in the best_depths array
  add x27, x27, #2          ; increase the maximum offset (allowed wasted characters)

  cmp x24, #(2 * -8)        ; check if we managed to visit all permutations last run
  b.ne next_subproblem      ; if we didn't, start working on solving the next subproblem

  mov x16, #1               ; system exit
  svc 0                     ; supervisor call

visit_12:
  str x30, [x29, -8]!       ; push the return address to the stack
  eor x0, x0, #1            ; mark 12 as visited

  cmp x29, x22              ; compare the stack pointer to the best depth so far
  csel x22, x29, x22, lt    ; store the current recursion depth if it is better

  ;;; 0 wasted characters ;;;
  tbnz x0, #5, after_12_21  ; if we've already visited 21, skip the next line
  bl visit_21               ; visit permutation 21
  after_12_21:

  ;;; 1 wasted character ;;;
  sub x26, x26, #2          ; visiting the following permutations wastes one more
                            ; character (moves the offset back 2-bytes / 16-bits)

  ldr x25, [x26]            ; read four 16-bit integers, corresponding to the
                            ; best extra recursion depths we could hope to add
                            ; for 1, 2, 3 and 4 additional wasted characters

  sbfx x24, x25, #48, #16   ; extract the first 16-bit integer from the register
  add x23, x29, x24         ; find the best recursion depth we could hope to reach

  cmp x23, x22              ; compare the reachable depth with the best depth
  b.lt waste_1_12           ; if the string could possibly beat it, keep going

  add x26, x26, #2          ; otherwise, reset the array offset to how it was...
  b unwind_12               ; ...and return early

  waste_1_12:
                            ; visit permutations that can be reached in 1 wasted character
                            ; (there aren't any for n=2)

  ;;; 2 wasted characters ;;;
  sub x26, x26, #2          ; based on the code above ^ but for one more wasted character
  sbfx x24, x25, #32, #16   ; extract the second 16-bit integer from the register
  add x23, x29, x24
  cmp x23, x22
  b.lt waste_2_12
  add x26, x26, #4
  b unwind_12
  waste_2_12:

                            ; visit permutations that can be reached in 2 wasted characters
                            ; ...

  ;;; 3 wasted characters ;;;
  sub x26, x26, #2          ; based on the code above ^ but for one more wasted character
  sbfx x24, x25, #16, #16   ; extract the third 16-bit integer from the register
  add x23, x29, x24
  cmp x23, x22
  b.lt waste_3_12
  add x26, x26, #6
  b unwind_12
  waste_3_12:
                            ; visit permutations that can be reached in 3 wasted characters
                            ; ...

  ;;; 4 wasted characters ;;;
  sub x26, x26, #2          ; based on the code above ^ but for one more wasted character
  sbfx x24, x25, #0, #16    ; extract the fourth 16-bit integer from the register
  add x23, x29, x24
  cmp x23, x22
  b.lt waste_4_12
  add x26, x26, #8
  b unwind_12
  waste_4_12:
                            ; visit permutations that can be reached in 4 wasted characters
                            ; ...


  add x26, x26, #8          ; reset the offset to how it was before if no branching occurred
  unwind_12:
  eor x0, x0, #1            ; mark 12 as unvisited
  ldr x30, [x29], #8        ; pop the return address from the stack
  ret

visit_21:
  sub x22, x29, #8
  ret ; omitted for brevity, this would follow the same kind of structure as above

init_best_depths:
  mov x0, #0                ; start from a 0-byte offset of the 'best_depths' array
  mov x1, #32767            ; write the 16-bit max value to the array (2^15 - 2)

  loop:
    str x1, [x28, x0]       ; set the 16-bit array element at the current offset
    add x0, x0, #2          ; advance the offset by one 16-bit integer
    cmp x0, #10             ; stop once we've written some number of elements
    b.ne loop

  ret

dot: .ascii ".\n"
